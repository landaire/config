{ inputs, ... }:
let
  install = [
    "com.discordapp.Discord"
    "com.chatterino.chatterino"
    "com.teamspeak.TeamSpeak3"
    "md.obsidian.Obsidian"
    "com.bitwarden.desktop"
    "org.audacityteam.Audacity"
    "fr.handbrake.ghb"
    "org.speedcrunch.SpeedCrunch"
    "com.spotify.Client"
    "dev.zed.Zed"
    "org.wezfurlong.wezterm"
    "org.kde.haruna"
    "org.filezillaproject.Filezilla"
    "io.github.mimbrero.WhatsAppDesktop"
  ];

  # System-scoped Bazzite defaults to remove.
  remove = [
    "org.mozilla.firefox"
  ];
in
{
  # Data the switch app reads.
  flake.flatpak = { inherit install remove; };

  perSystem =
    { system, ... }:
    let
      # No shared perSystem `pkgs` is wired up yet in this flake, so import locally.
      pkgs = import inputs.nixpkgs { inherit system; };
      inherit (pkgs.lib.strings) concatStringsSep;
      inherit (pkgs.lib.attrsets) optionalAttrs;
      installLine = concatStringsSep " " install;
      removeLine = concatStringsSep " " remove;
    in
    optionalAttrs pkgs.stdenv.isLinux {
      packages.flatpak-sync = pkgs.writeShellApplication {
        name = "flatpak-sync";
        runtimeInputs = [ pkgs.flatpak ];
        text = /* bash */ ''
          set -euo pipefail

          echo "ensuring flathub remote (user)..."
          flatpak remote-add --user --if-not-exists flathub \
            https://dl.flathub.org/repo/flathub.flatpakrepo

          echo "installing declared apps (user)..."
          for app in ${installLine}; do
            if ! flatpak info --user "$app" >/dev/null 2>&1; then
              flatpak install --user --noninteractive --or-update flathub "$app"
            fi
          done

          echo "removing declared bloat (system + user)..."
          for app in ${removeLine}; do
            if flatpak info --system "$app" >/dev/null 2>&1; then
              sudo flatpak uninstall --system --noninteractive "$app" || true
            fi
            if flatpak info --user "$app" >/dev/null 2>&1; then
              flatpak uninstall --user --noninteractive "$app" || true
            fi
          done

          echo "flatpak sync done."
        '';
      };
    };
}
