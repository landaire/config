{ inputs, lib, self, ... }:
{
  perSystem =
    { system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") (
      let
        inherit (lib.strings) toJSON;

        # No shared perSystem `pkgs` is wired up yet in this flake, so import locally.
        pkgs = import inputs.nixpkgs { inherit system; };

        # smfh is hjem's file linker. We drive it directly (like ncc's
        # managed-files) instead of the `hjem standalone` CLI, which only
        # nix-evals the manifest (skipping unbuilt sources) and layers on
        # generations/state that desync. `activate` re-links missing files every
        # run, so there is no stale-state trap.
        smfhBin = "${inputs.hjem.packages.${system}.smfh}/bin/smfh";
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
          # Packages that need OS integration (Helium, Sunshine, tailscale,
          # openssh-server) and waydroid removal all live in the bazzite-nix
          # image, not here. This step only applies host config that is not
          # baked into the image.

          print "== helium managed policies =="
          for dir in ["/etc/chromium/policies/managed" "/etc/helium/policies/managed"] {
            ^sudo install -d $dir
            ^sudo install -m 0644 ${heliumPolicyJson} $"($dir)/policy.json"
          }

          print "== ssh firewall =="
          # sshd itself is enabled in the image; only opening the port is host
          # state (firewalld config lives outside the image).
          if (which firewall-cmd | is-not-empty) {
            try { ^sudo firewall-cmd --permanent --add-service=ssh } catch { }
            try { ^sudo firewall-cmd --reload } catch { }
          }

          print "provision done. If tailscale is not up yet, run: tailscale up"
        '';

        switch = pkgs.writers.writeNuBin "richese-switch" ''
          let smfh = "${smfhBin}"
          let tools = "${tools}"
          let flatpak_sync = "${flatpakSync}"
          let provision_bin = "${provision}/bin/richese-provision"
          let manifest_file = "${richeseManifest}"

          def do-home [] {
            print "== home (link managed files) =="
            # Drive smfh directly (ncc-style). The manifest's sources are already
            # realized (they are inputs of ${richeseManifest}). diff --fallback
            # applies changes vs the last-applied manifest (or links all on first
            # run); activate then re-links anything missing, so nothing desyncs.
            let current = ($env.HOME | path join ".local/state/richese/manifest.json")
            mkdir ($current | path dirname)
            ^($smfh) diff $manifest_file $current --fallback
            ^($smfh) activate $manifest_file
            cp --force $manifest_file $current
            print "== packages (nix profile) =="
            # Installing by store path cannot upgrade in place and accumulates
            # duplicate entries, so remove any prior richese-tools first, then
            # install the current one.
            do { ^nix profile remove --regex 'richese-tools.*' } | complete | ignore
            do { ^nix profile install $tools } | complete | ignore
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
