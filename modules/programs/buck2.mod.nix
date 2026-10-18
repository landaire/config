{
  # buck2 reads ~/.buckconfig.d before a project's .buckconfig, so a project
  # can still override these or opt out entirely. It skips entries that are
  # not regular files, so a file meant to apply must be a copy rather than a
  # store symlink.
  flake.homeModules.buck2 =
    { lib, isPersonal, ... }:
    let
      inherit (lib.generators) toINI;
      inherit (lib.modules) mkIf mkMerge;

      # junction's tailnet name. The buck2 that projects pin through DotSlash is
      # a static musl binary, which resolves names only through /etc/hosts and
      # DNS, so the mDNS name junction.local does not work for it. Tailscale
      # also encrypts the gRPC, and the name works away from home.
      endpoint = "grpc://junction.tail8a811.ts.net:50051";
    in
    mkMerge [
      {
        # watchman already watches the repositories for jj's fsmonitor.
        # buck2's own inotify watcher adds a watch for every directory,
        # buck-out included, and next to watchman it runs out of
        # fs.inotify.max_user_watches.
        files.".buckconfig.d/20-file-watcher" = {
          type = "copy";
          generator = toINI { };
          value.buck2.file_watcher = "watchman";
        };
      }

      # Points the personal hosts at junction's NativeLink cluster.
      # Deliberately not the work host: that would route work sources and
      # artifacts to a personal box. Declaring the endpoint does not by itself
      # send work remotely: a project's execution platform decides that.
      (mkIf isPersonal {
        files.".buckconfig.d/10-remote-execution" = {
          type = "copy";
          generator = toINI { };
          value = {
            buck2_re_client = {
              engine_address = endpoint;
              action_cache_address = endpoint;
              cas_address = endpoint;
              tls = false;
            };

            # Upload results for any action that does not decide for itself.
            # Cache *reads* cannot be enabled from here: they come from the
            # execution platform, which is per project.
            buck2.default_allow_cache_upload = true;
          };
        };
      })
    ];
}
