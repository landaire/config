# Radicle seed node in a NixOS container, with an hourly job that mirrors every
# non-fork GitHub repository of the token's account into it. GitHub private
# repositories are stored as private Radicle repositories that the node does
# not seed (see radicle/mirror.nu), and radicle-httpd does not serve them.
#
# The mirror reads a GitHub token from secrets/radicle-github-token.age.
# The node key is generated inside the container on first start.
{
  flake.nixosModules.radicle =
    { lib, ... }:
    let
      alias = "junction";
      nodePort = 8776;
      httpdPort = 8080;
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
            [
              nodePort
              httpdPort
            ];

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

            # Marked for the 1.x transport flaws, which expose private
            # repositories only; the mirror never seeds those.
            # https://radicle.dev/2026/09/23/disclosure-of-vulnerability-in-network-protocol
            nixpkgs.config.permittedInsecurePackages = [ "radicle-node-1.10.3" ];

            services.radicle = {
              enable = true;
              privateKey = "${keysDir}/radicle";
              publicKey = "${keysDir}/radicle.pub";
              node.openFirewall = true;
              settings = {
                # A config.json without this key has no seeds at all; these are
                # the clearnet entries `rad auth` writes.
                preferredSeeds = [
                  "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@iris.radicle.network:8776"
                  "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@rosa.radicle.network:8776"
                ];
                node = {
                  inherit alias;
                  # The mirror relies on this while a repository changes
                  # visibility, and it keeps the node from seeding other peers'
                  # repositories.
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
                LoadCredential = "github-token:/run/secrets/radicle/github-token";
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
      age.secrets.radicle-github-token = {
        file = ../secrets/radicle-github-token.age;
        path = "${secretsDir}/github-token";
        symlink = false;
      };
      systemd.tmpfiles.rules = [ "d ${secretsDir} 0700 root root -" ];
    };
}
