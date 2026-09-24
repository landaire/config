# NativeLink as a single-process REAPI cluster: CAS, action cache, scheduler and
# one local worker. Buck2, Bazel and anything else speaking Remote Execution v2
# point at one port. Adapted from the upstream local_rbe_self_test example.
{ inputs, ... }:
{
  flake.nixosModules.buck2-remote-execution =
    { pkgs, lib, ... }:
    let
      inherit (lib.strings) makeBinPath;

      stateDir = "/var/lib/nativelink";
      clientPort = 50051;
      # Workers dial this; clients never do, so it stays on loopback.
      workerPort = 50061;

      gib = n: n * 1024 * 1024 * 1024;

      fsStore = name: bytes: {
        inherit name;
        filesystem = {
          content_path = "${stateDir}/${name}/content";
          temp_path = "${stateDir}/${name}/tmp";
          eviction_policy.max_bytes = bytes;
        };
      };

      # The worker calls env_clear() on every action, so a PATH on the unit does
      # nothing; it has to be handed over via additional_environment below.
      # There is no container isolation: extend this with whatever toolchain
      # your buck2 rules actually invoke.
      workerTools = with pkgs; [
        bash
        coreutils
        findutils
        gnugrep
        diffutils
        gnused
        gnutar
        gzip
        which
        gcc
        binutils
        pkg-config
        python3
      ];

      settings = {
        stores = [
          (fsStore "cas" (gib 200))
          (fsStore "ac" (gib 4))
          {
            name = "worker";
            fast_slow = {
              # `fast` must be a filesystem store: the worker hardlinks out of
              # it to assemble each action's sandbox.
              fast.filesystem = {
                content_path = "${stateDir}/worker/content";
                temp_path = "${stateDir}/worker/tmp";
                eviction_policy.max_bytes = gib 100;
              };
              # Sharing the client-facing CAS makes worker output immediately
              # visible to clients.
              slow.ref_store.name = "cas";
            };
          }
        ];

        schedulers = [
          {
            name = "main";
            simple.supported_platform_properties = {
              cpu_count = "minimum";
              OSFamily = "priority";
              "container-image" = "priority";
            };
          }
        ];

        workers = [
          {
            local = {
              worker_api_endpoint.uri = "grpc://127.0.0.1:${toString workerPort}";
              cas_fast_slow_store = "worker";
              upload_action_result.ac_store = "ac";
              work_directory = "${stateDir}/work";
              additional_environment.PATH.value = makeBinPath workerTools;
              platform_properties = {
                cpu_count.values = [ "32" ];
                OSFamily.values = [
                  ""
                  "linux"
                  "Linux"
                ];
                "container-image".values = [ "" ];
              };
            };
          }
        ];

        servers = [
          {
            name = "client";
            listener.http.socket_address = "0.0.0.0:${toString clientPort}";
            services = {
              cas = [ { cas_store = "cas"; } ];
              ac = [ { ac_store = "ac"; } ];
              bytestream = [ { cas_store = "cas"; } ];
              execution = [
                {
                  cas_store = "cas";
                  scheduler = "main";
                }
              ];
              capabilities = [ { remote_execution.scheduler = "main"; } ];
            };
          }
          {
            name = "worker_api";
            listener.http.socket_address = "127.0.0.1:${toString workerPort}";
            services = {
              worker_api.scheduler = "main";
              health = { };
            };
          }
        ];

        global.max_open_files = 24576;
      };

      # JSON5 is a superset of JSON, so the generated file loads as-is.
      configFile = pkgs.writeText "nativelink.json" (builtins.toJSON settings);

      nativelink = inputs.nativelink.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      systemd.services.nativelink = {
        description = "NativeLink remote execution and cache server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          ExecStart = "${nativelink}/bin/nativelink ${configFile}";
          Restart = "on-failure";
          RestartSec = 5;

          StateDirectory = "nativelink";
          WorkingDirectory = stateDir;
          DynamicUser = true;

          LimitNOFILE = 65536;
        };
      };

      networking.firewall.allowedTCPPorts = [ clientPort ];
    };
}
