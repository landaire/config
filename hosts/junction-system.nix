{
  config,
  pkgs,
  ...
}: let
  projectDirectory = "/home/lander/dev/spotify-playlist";
  syncSpotifyPlaylists = pkgs.writeShellScript "sync-spotify-playlists" ''
    set -eu
    export SPOTIFY_PLAYLIST_CONFIG_FILE="$CREDENTIALS_DIRECTORY/spotify-config"
    exec ${pkgs.devenv}/bin/devenv shell -- \
      buck2 --isolation-dir spotify-playlist-sync run //:spotify-playlist -- sync
  '';
in {
  imports = [./junction-hardware.nix];

  allowedUnfreePackageNames = [
    "nvidia-kernel-modules"
    "nvidia-x11"
  ];

  age.secrets.spotify-playlist-config.file = ../secrets/spotify-playlist-config.age;
  age.secrets.spotify-playlist-session.file = ../secrets/spotify-playlist-session.age;

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = false;
    open = false;
    powerManagement.enable = false;
  };

  programs.nix-ld = {
    enable = true;
    libraries = [pkgs.stdenv.cc.cc];
  };

  systemd.tmpfiles.rules = [
    "L+ /usr/bin/ar - - - - ${pkgs.binutils}/bin/ar"
    "L+ /usr/bin/clang - - - - ${pkgs.clang}/bin/clang"
    "L+ /usr/bin/clang++ - - - - ${pkgs.clang}/bin/clang++"
    "d /home/lander/.buck 0700 lander users -"
    "d /home/lander/.cache/huggingface 0700 lander users -"
    "d /home/lander/.cache/nix 0700 lander users -"
    "d /home/lander/.local/state/watchman 0700 lander users -"
  ];

  services.xserver.videoDrivers = ["nvidia"];

  users.users.lander.extraGroups = [
    "render"
    "video"
  ];

  systemd.services.spotify-playlist-sync = {
    description = "Synchronize Echo District Spotify playlists";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    restartIfChanged = false;
    environment = {
      HOME = "/home/lander";
      SPOTIFY_PLAYLIST_SESSION_FILE = "/var/lib/spotify-playlist/session.json";
      SPOTIFY_PLAYLIST_STATE_FILE = "/var/lib/spotify-playlist/managed-playlists.json";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "lander";
      Group = "users";
      SupplementaryGroups = [
        "render"
        "video"
      ];
      WorkingDirectory = projectDirectory;
      ExecStart = syncSpotifyPlaylists;
      LoadCredential = [
        "spotify-config:${config.age.secrets.spotify-playlist-config.path}"
        "spotify-session:${config.age.secrets.spotify-playlist-session.path}"
      ];
      StateDirectory = "spotify-playlist";
      StateDirectoryMode = "0700";
      UMask = "0077";
      TimeoutStartSec = "20h";
      Nice = 10;
      IOSchedulingClass = "idle";

      NoNewPrivileges = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = "read-only";
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        projectDirectory
        "-/home/lander/.buck"
        "-/home/lander/.cache/nix"
        "-/home/lander/.cache/huggingface"
        "-/home/lander/.local/state/watchman"
        "/tmp"
      ];
    };
  };

  systemd.timers.spotify-playlist-sync = {
    description = "Daily Echo District Spotify playlist synchronization";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
      AccuracySec = "1m";
    };
  };
}
