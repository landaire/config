{
  flake.darwinModules.apps =
    {
      pkgs,
      lib,
      isPersonal,
      ...
    }:
    let
      inherit (lib.modules) mkIf mkMerge;
    in
    {
      config = mkMerge [
        {
          # Unfree allowlist (replaces blanket allowUnfree). Extend as builds reveal more.
          allowedUnfreePackageNames = [
            "claude-code"
          ];

          # COMMON CLI (home-owned tools omitted: nushell/zoxide/starship/atuin/jj/lazyjj/difftastic/bat/ripgrep)
          environment.systemPackages = with pkgs; [
            nh
            fd
            git
            tealdeer
            watchman
            curl
            wget
            p7zip
            yt-dlp
            doggo
            mise
            procs
            sd
            skim
            gh
            hexyl
            eza
            ffmpeg
            imagemagick
            python3
            rage
            crabz
            fzf
            git-cliff
            nil
            alejandra
            just
            httpie
            htop
            bottom
            hyperfine
            jaq
            neovim
            uv
            sccache
            protobuf
            delta
            rustup
          ];

          # COMMON HOMEBREW
          homebrew.brews = [
            "coreutils"
            "pkg-config"
            "ninja"
            "cmake"
          ];
          homebrew.casks = [
            "wezterm"
            "zed"
            "raycast"
            "firefox"
            "jordanbaird-ice"
            "010-editor"
            "monodraw"
            "keepingyouawake"
            "speedcrunch"
            "imhex"
          ];
        }

        (mkIf isPersonal {
          environment.systemPackages = with pkgs; [
            sendme
            bacon
            kondo
            zola
            asciinema
            mdbook
            claude-code
            codex
            trunk
            mergiraf
            opencode
          ];

          homebrew.taps = [ "nikitabobko/tap" ];
          homebrew.brews = [
            "twitch-cli"
            "dylibbundler"
            "cargo-binstall"
          ];
          homebrew.casks = [
            "tailscale-app"
            "iina"
            "audacity"
            "chatterino"
            "DevUtils"
            "gcloud-cli"
            "handbrake-app"
            "macfuse"
            "keycastr"
            "dotnet-sdk"
            "spotify"
            "cleanshot"
            "proton-mail"
            "proton-pass"
            "proton-drive"
            "protonvpn"
            "obsidian"
            "discord"
            "signal"
            "telegram"
            "claude"
            "nikitabobko/tap/aerospace"
            "transmit"
            "glide"
            "bitwarden"
          ];
          homebrew.masApps = {
            "WhatsApp" = 310633997;
            "Peek" = 1554235898;
            "Windows" = 1295203466;
          };
        })
      ];
    };
}
