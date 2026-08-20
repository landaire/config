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

        heliumPolicy = (import ./web-browser/policy.nix { inherit lib inputs; }).policy;
        heliumPolicyJson = pkgs.writeText "helium-policy.json" (toJSON heliumPolicy);

        provision = pkgs.writeShellApplication {
          name = "richese-provision";
          runtimeInputs = [ pkgs.coreutils ];
          text = /* bash */ ''
            set -euo pipefail
            echo "== rpm-ostree layer (needs sudo; applies on reboot) =="

            # Remove preinstalled bloat (verify the exact name on your image).
            if rpm-ostree status | grep -q ' waydroid'; then
              sudo rpm-ostree override remove waydroid || \
                echo "waydroid override-remove failed; check the package name (ujust may help)."
            fi

            # Tailscale daemon.
            if ! command -v tailscale >/dev/null 2>&1; then
              sudo rpm-ostree install tailscale || true
            fi

            # Helium binary via official COPR.
            if ! command -v helium >/dev/null 2>&1 && ! test -e /var/lib/flatpak/exports/bin/net.imput.helium; then
              sudo bash -c 'dnf copr enable -y imput/helium && rpm-ostree install helium-bin' || \
                echo "helium-bin COPR install failed; fall back to the AppImage from imputnet/helium-linux."
            fi

            echo "== helium managed policies =="
            for dir in /etc/chromium/policies/managed /etc/helium/policies/managed; do
              sudo install -d "$dir"
              sudo install -m 0644 ${heliumPolicyJson} "$dir/policy.json"
            done

            echo "provision done. Reboot to apply rpm-ostree changes, then run: tailscale up"
          '';
        };

        switch = pkgs.writeShellApplication {
          name = "richese-switch";
          runtimeInputs = [ pkgs.nix ];
          text = /* bash */ ''
            set -euo pipefail
            scope="all"
            flake="."
            for arg in "$@"; do
              case "$arg" in
                --home) scope="home" ;;
                --apps) scope="apps" ;;
                --system) scope="system" ;;
                --all) scope="all" ;;
                --flake=*) flake="''${arg#--flake=}" ;;
                *) echo "usage: richese-switch [--home|--apps|--system|--all] [--flake=REF]"; exit 2 ;;
              esac
            done

            do_home() {
              echo "== home (hjem standalone switch) =="
              ${hjemCli} standalone switch --flake "$flake" --flake-attr 'hjemConfigurations."richese".manifest'
              echo "== packages (nix profile) =="
              nix profile install ${tools} 2>/dev/null || nix profile upgrade ${tools} 2>/dev/null || true
            }
            do_apps() { echo "== apps (flatpak) =="; ${flatpakSync}; }
            do_system() { ${provision}/bin/richese-provision; }

            if [ "$scope" != "home" ]; then sudo -v; fi
            case "$scope" in
              home) do_home ;;
              apps) do_apps ;;
              system) do_system ;;
              all) do_home; do_apps; do_system ;;
            esac
            echo "richese-switch ($scope) complete."
          '';
        };
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
