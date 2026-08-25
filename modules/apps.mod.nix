{
  flake.darwinModules.apps = {
    pkgs,
    lib,
    isPersonal,
    inputs,
    ...
  }: let
    inherit (lib.modules) mkIf mkMerge;
    pkgLists = import ./packages.nix { inherit pkgs inputs; };
  in {
    config = mkMerge [
      {
        # Unfree allowlist (replaces blanket allowUnfree). Extend as builds reveal more.
        allowedUnfreePackageNames = [
          "claude-code"
          "google-cloud-sdk"
          "dotnet-sdk"
        ];

        # COMMON CLI (home-owned tools omitted: nushell/zoxide/starship/atuin/jj/lazyjj/difftastic/bat/ripgrep)
        environment.systemPackages = pkgLists.common;

        # COMMON HOMEBREW
        homebrew.brews = [
          "coreutils"
        ];
        homebrew.casks = [
          "wezterm@nightly"
          "zed"
          "raycast"
          "firefox"
          "helium-browser"
          "jordanbaird-ice"
          "monodraw"
          "keepingyouawake"
          "speedcrunch"
        ];
      }

      (mkIf isPersonal {
        environment.systemPackages = pkgLists.personal;

        homebrew.brews = [
          "twitch-cli"
        ];
        homebrew.casks = [
          "tailscale-app"
          "iina"
          "audacity"
          "chatterino"
          "DevUtils"
          "handbrake-app"
          "macfuse"
          "keycastr"
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
          "transmit"
          "glide"
          "bitwarden"
        ];
        homebrew.masApps = {
          "WhatsApp" = 310633997;
          "Peek" = 1554235898;
          "Windows" = 1295203466;
          "Xcode" = 497799835;
        };
      })
    ];
  };

  flake.homeModules.apps =
    { pkgs, isPersonal, inputs, lib, ... }:
    let
      inherit (lib.lists) optionals;
      pkgLists = import ./packages.nix { inherit pkgs inputs; };
    in
    {
      packages = pkgLists.common ++ optionals isPersonal pkgLists.personal;
    };
}
