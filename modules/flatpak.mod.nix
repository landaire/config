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
    "org.rncbc.qpwgraph"
    "org.filezillaproject.Filezilla"
    "io.github.mimbrero.WhatsAppDesktop"
    "dev.lizardbyte.app.Sunshine"
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
      inherit (pkgs.lib.strings) concatMapStringsSep;
      inherit (pkgs.lib.attrsets) optionalAttrs;
      nuList = concatMapStringsSep " " (x: ''"${x}"'');
      installListNu = nuList install;
      removeListNu = nuList remove;
    in
    optionalAttrs pkgs.stdenv.isLinux {
      packages.flatpak-sync = pkgs.writers.writeNuBin "flatpak-sync" ''
        print "ensuring flathub remote (user)..."
        ^flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

        print "installing declared apps (user)..."
        let install_apps = [${installListNu}]
        for app in $install_apps {
          if (try { ^flatpak info --user $app | complete } catch { {exit_code: 1} }).exit_code != 0 {
            ^flatpak install --user --noninteractive --or-update flathub $app
          }
        }

        print "removing declared bloat (system + user)..."
        let remove_apps = [${removeListNu}]
        for app in $remove_apps {
          if (try { ^flatpak info --system $app | complete } catch { {exit_code: 1} }).exit_code == 0 {
            try { ^sudo flatpak uninstall --system --noninteractive $app } catch { print "system uninstall failed (non-fatal)." }
          }
          if (try { ^flatpak info --user $app | complete } catch { {exit_code: 1} }).exit_code == 0 {
            try { ^flatpak uninstall --user --noninteractive $app } catch { print "user uninstall failed (non-fatal)." }
          }
        }

        print "flatpak sync done."
      '';
    };
}
