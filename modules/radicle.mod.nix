# Radicle seed node in a NixOS container, with an hourly job that mirrors an
# explicit GitHub repository allow list into it. Private repositories are
# allow-listed for the configured Radicle Garden node (see radicle/mirror.nu).
#
# The mirror reads a GitHub token from secrets/radicle-github-token.age.
# The node key is generated inside the container on first start.
{
  flake.nixosModules.radicle =
    { lib, ... }:
    let
      alias = "junction";
      httpdPort = 8080;
      gardenAddress = "z6MkrwUPtWaeqYEAS4YzPfzc94UQQFBpPqVVEw2vHKun2Tgy@lander.radicle.garden:58038";
      officialSeeds = [
        "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@iris.radicle.network:8776"
        "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@rosa.radicle.network:8776"
      ];
      trustedPeers = officialSeeds ++ [ gardenAddress ];
      secretsDir = "/var/lib/secrets/radicle";
      radHome = "/var/lib/radicle";
      # Outside radHome, which radicle-httpd also mounts. The node gets the
      # secret key as a credential and the mirror through a bind mount.
      keysDir = "/var/lib/radicle-keys";
    in
    {
      containers.radicle = {
        autoStart = true;
        privateNetwork = true;
        hostAddress = "10.233.1.1";
        localAddress = "10.233.1.2";
        forwardPorts =
          map
            (port: {
              containerPort = port;
              hostPort = port;
              protocol = "tcp";
            })
            [ httpdPort ];

        bindMounts.secrets = {
          hostPath = secretsDir;
          mountPoint = "/run/secrets/radicle";
        };

        config =
          { config, pkgs, ... }:
          let
            cfg = config.services.radicle;

            mirror = pkgs.writers.writeNuBin "radicle-mirror" {
              makeWrapperArgs = [
                "--prefix"
                "PATH"
                ":"
                (lib.makeBinPath [
                  cfg.package
                  pkgs.gh
                  pkgs.git
                ])
              ];
            } (builtins.readFile ./radicle/mirror.nu);
          in
          {
            system.stateVersion = "26.05";

            # Marked for the 1.x transport flaws. Allow-listing a private
            # repository does not prevent a peer from impersonating an allowed
            # DID and fetching it.
            # https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol
            nixpkgs.config.permittedInsecurePackages = [ "radicle-node-1.10.3" ];

            services.radicle = {
              enable = true;
              privateKey = "${keysDir}/radicle";
              publicKey = "${keysDir}/radicle.pub";
              # The node only initiates sessions with the static trusted peer
              # set and rejects non-local inbound sessions. Port 8776 is not
              # opened or forwarded.
              node.openFirewall = false;
              settings = {
                preferredSeeds = trustedPeers;
                node = {
                  inherit alias;
                  connect = trustedPeers;
                  externalAddresses = [ ];
                  limits.connection.inbound = 0;
                  peers.type = "static";
                  # The mirror creates explicit allow policies only for its
                  # repository list and removes stale policies after each run.
                  # Everything else remains blocked.
                  seedingPolicy.default = "block";
                };
              };
              httpd = {
                enable = true;
                listenAddress = "0.0.0.0";
                listenPort = httpdPort;
              };
            };
            networking.firewall.allowedTCPPorts = [ httpdPort ];

            # Unencrypted so the node and the mirror run unattended.
            systemd.services.radicle-keygen = {
              description = "Radicle node key generation";
              wantedBy = [
                "radicle-node.service"
                "radicle-httpd.service"
              ];
              before = [
                "radicle-node.service"
                "radicle-httpd.service"
              ];
              unitConfig.ConditionPathExists = "!${keysDir}/radicle";
              path = [ cfg.package ];
              environment.RAD_PASSPHRASE = "";
              serviceConfig = {
                Type = "oneshot";
                User = "radicle";
                Group = "radicle";
                StateDirectory = "radicle-keys";
                StateDirectoryMode = "0700";
                PrivateTmp = true;
              };
              script = ''
                tmp=$(mktemp -d)
                RAD_HOME=$tmp rad auth --alias ${alias}
                mv "$tmp/keys/radicle" "$tmp/keys/radicle.pub" ${keysDir}/
                rm -rf "$tmp"
              '';
            };

            systemd.services.radicle-mirror = {
              description = "Mirror GitHub repositories into Radicle";
              requires = [ "radicle-node.service" ];
              wants = [ "network-online.target" ];
              after = [
                "radicle-node.service"
                "network-online.target"
              ];
              environment = {
                HOME = "/var/lib/radicle-mirror";
                RAD_HOME = radHome;
              };
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${mirror}/bin/radicle-mirror";
                User = "radicle";
                Group = "radicle";
                StateDirectory = "radicle-mirror";
                LoadCredential = [
                  "github-token:/run/secrets/radicle/github-token"
                  "landaire-contrib-token:/run/secrets/radicle/landaire-contrib-token"
                ];
                BindReadOnlyPaths = [
                  "${cfg.configFile}:${radHome}/config.json"
                  "${keysDir}/radicle:${radHome}/keys/radicle"
                  "${keysDir}/radicle.pub:${radHome}/keys/radicle.pub"
                ];
                ReadWritePaths = [ radHome ];
                ProtectSystem = "strict";
                ProtectHome = true;
                PrivateTmp = true;
                NoNewPrivileges = true;
              };
            };

            systemd.timers.radicle-mirror = {
              wantedBy = [ "timers.target" ];
              timerConfig = {
                OnCalendar = "hourly";
                Persistent = true;
              };
            };
          };
      };

      # By default a switch stops machined and its socket, then starts the
      # socket. The stopping container's unregister call bus-activates machined
      # in that gap, so the socket fails to start and the switch reports
      # failure. A restart leaves the socket listening.
      systemd.services.systemd-machined.stopIfChanged = false;

      networking.nat = {
        enable = true;
        internalInterfaces = [ "ve-radicle" ];
      };

      # Copied rather than symlinked into /run/agenix, which the container
      # cannot see; the container bind-mounts the directory.
      age.secrets = {
        radicle-github-token = {
          file = ../secrets/radicle-github-token.age;
          path = "${secretsDir}/github-token";
          symlink = false;
        };
        radicle-landaire-contrib-token = {
          file = ../secrets/radicle-landaire-contrib-token.age;
          path = "${secretsDir}/landaire-contrib-token";
          symlink = false;
        };
      };
      systemd.tmpfiles.rules = [ "d ${secretsDir} 0700 root root -" ];
    };
}
