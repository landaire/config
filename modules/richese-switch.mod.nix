{ inputs, lib, self, ... }:
{
  perSystem =
    { system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") (
      let
        inherit (lib.strings) toJSON;

        # No shared perSystem `pkgs` is wired up yet in this flake, so import locally.
        pkgs = import inputs.nixpkgs { inherit system; };

        hjemCli = "${inputs.hjem.packages.${system}.hjem}/bin/hjem";
        # richese-tools is a flake-level package (set by hjemSystem), read via self.
        tools = self.packages.${system}.richese-tools;
        # flatpak-sync is a sibling flake-level package, read via self to avoid
        # coupling to perSystem `config` (which risks recursion in this flake).
        flatpakSync = "${self.packages.${system}.flatpak-sync}/bin/flatpak-sync";
        # Built manifest (all sources realized). Referencing it here puts the whole
        # source closure in richese-switch's runtime closure, so `nix run` builds
        # the configs before the switch links them - no separate build step.
        richeseManifest = self.packages.${system}.richese-manifest;

        heliumPolicy = (import ./web-browser/policy.nix { inherit lib inputs; }).policy;
        heliumPolicyJson = pkgs.writeText "helium-policy.json" (toJSON heliumPolicy);

        provision = pkgs.writers.writeNuBin "richese-provision" ''
          print "== rpm-ostree layer (needs sudo; applies on reboot) =="

          # Remove preinstalled bloat (verify the exact name on your image).
          if (try { ^rpm-ostree status | ^grep -q ' waydroid' | complete } catch { {exit_code: 1} }).exit_code == 0 {
            try {
              ^sudo rpm-ostree override remove waydroid
            } catch {
              print "waydroid override-remove failed; check the package name (ujust may help)."
            }
          }

          # Tailscale daemon.
          if (which tailscale | is-empty) {
            try { ^sudo rpm-ostree install tailscale } catch { }
          }

          # Helium binary via official COPR.
          if (which helium | is-empty) and not ("/var/lib/flatpak/exports/bin/net.imput.helium" | path exists) {
            try {
              ^sudo bash -c 'dnf copr enable -y imput/helium && rpm-ostree install helium-bin'
            } catch {
              print "helium-bin COPR install failed; fall back to the AppImage from imputnet/helium-linux."
            }
          }

          print "== helium managed policies =="
          for dir in ["/etc/chromium/policies/managed" "/etc/helium/policies/managed"] {
            ^sudo install -d $dir
            ^sudo install -m 0644 ${heliumPolicyJson} $"($dir)/policy.json"
          }

          print "== sshd =="
          if (try { ^systemctl cat sshd.service | complete } catch { {exit_code: 1} }).exit_code == 0 {
            try { ^sudo systemctl enable --now sshd } catch { print "failed to enable sshd (non-fatal)." }
            if (which firewall-cmd | is-not-empty) {
              try { ^sudo firewall-cmd --permanent --add-service=ssh } catch { }
              try { ^sudo firewall-cmd --reload } catch { }
            }
          } else {
            print "sshd unit not found; installing openssh-server (reboot required)."
            try { ^sudo rpm-ostree install openssh-server } catch { print "install openssh-server manually." }
          }

          print "provision done. Reboot to apply rpm-ostree changes, then run: tailscale up"
        '';

        switch = pkgs.writers.writeNuBin "richese-switch" ''
          let hjem_cli = "${hjemCli}"
          let tools = "${tools}"
          let flatpak_sync = "${flatpakSync}"
          let provision_bin = "${provision}/bin/richese-provision"
          let manifest_file = "${richeseManifest}"

          def do-home [] {
            print "== home (hjem standalone switch) =="
            # Pass the built manifest file: its sources are already realized (they
            # are inputs of ${richeseManifest}), so smfh actually links them.
            ^($hjem_cli) standalone switch --manifest $manifest_file
            print "== packages (nix profile) =="
            if (do { ^nix profile install $tools } | complete | get exit_code) != 0 {
              do { ^nix profile upgrade $tools } | complete | ignore
            }
            print "== KDE panel =="
            # Plasma panel prefs via the desktop scripting API. Needs a live
            # Plasma session, so this no-ops on headless / pre-login runs.
            let panel_js = 'var ps = panels(); for (var i = 0; i < ps.length; i++) { var p = ps[i]; p.location = "top"; p.alignment = "center"; p.hiding = "autohide"; p.floating = true; p.opacity = "adaptive"; p.lengthMode = "fit"; }'
            let qdbus_bin = if (which qdbus6 | is-not-empty) {
              "qdbus6"
            } else if (which qdbus | is-not-empty) {
              "qdbus"
            } else {
              ""
            }
            # Non-fatal: a transient panel-scripting failure must not abort the switch.
            if $qdbus_bin == "" {
              print "no live Plasma session; skipping panel config."
            } else if (^($qdbus_bin) org.kde.plasmashell | complete | get exit_code) != 0 {
              print "no live Plasma session; skipping panel config."
            } else if (^($qdbus_bin) org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript $panel_js | complete | get exit_code) == 0 {
              print "panel configured."
            } else {
              print "panel scripting call failed (non-fatal)."
            }
          }

          def do-apps [] {
            print "== apps (flatpak) =="
            ^($flatpak_sync)
          }

          def do-system [] {
            ^($provision_bin)
          }

          def main [--home, --apps, --system, --all] {
            let scope = if $home {
              "home"
            } else if $apps {
              "apps"
            } else if $system {
              "system"
            } else {
              "all"
            }

            if $scope != "home" { ^sudo -v }
            if $scope == "home" {
              do-home
            } else if $scope == "apps" {
              do-apps
            } else if $scope == "system" {
              do-system
            } else {
              do-home
              do-apps
              do-system
            }
            print $"richese-switch \(($scope)\) complete."
          }
        '';
      in
      {
        packages.richese-provision = provision;
        packages.richese-switch = switch;
        apps.richese-switch = {
          type = "app";
          program = "${switch}/bin/richese-switch";
        };
      }
    );
}
