{
  inputs,
  lib,
  ...
}: let
  inherit (import ./web-browser/policy.nix {inherit lib inputs;}) policy preferences;
in {
  flake.darwinModules.helium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) mapAttrsToList;
    inherit (lib.generators) toPlist;
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkAfter;
    inherit (lib.strings) toJSON;
    inherit (lib.shell) asShell;

    policyFiles =
      [
        {
          path = "/Library/Managed Preferences/net.imput.helium.plist";
          content = toPlist {escape = true;} policy;
        }
      ]
      ++ (
        policy."3rdparty".extensions
        |> mapAttrsToList (
          id: extensionPolicy: {
            path = "/Library/Managed Preferences/net.imput.helium.extensions.${id}.plist";
            content = toPlist {escape = true;} extensionPolicy;
          }
        )
      );
  in {
    system.activationScripts.postActivation.text = mkAfter ''
      ${config.system.activationScripts.helium.text}
    '';
    system.activationScripts.helium.text =
      asShell pkgs.nushell "helium-policy.nu"
      /*
      nu
      */
      ''
        print "setting up helium policy..."

        mkdir `/Library/Managed Preferences`

        for entry in (r#'${toJSON policyFiles}'# | from json) {
          $entry.content | save --force $entry.path
          ^chown root:wheel $entry.path
          ^chmod 0644 $entry.path
        }

        (^/usr/bin/sudo
          --user (ls --long /dev/console | get 0.user)
          ${getExe pkgs.defaultbrowser} helium)
      '';
  };

  flake.homeModules.helium = {
    lib,
    osConfig,
    ...
  }: let
    inherit (lib.modules) mkIf;
    inherit (lib.strings) toJSON;

    defaultPreferences.type = "copy";
    defaultPreferences.text = toJSON preferences;
  in {
    # Helium.app is installed via the `helium-browser` homebrew cask
    # (modules/apps.mod.nix); this module only writes its default Preferences.
    files."Library/Application Support/net.imput.helium/Default/Preferences" =
      mkIf osConfig.nixpkgs.hostPlatform.isDarwin defaultPreferences;
  };

  # Helium user Preferences on linux (managed policies are written by the
  # richese-switch --system step; the binary comes from the helium-bin COPR).
  flake.homeModules.helium-linux = {lib, ...}: let
    inherit (lib.strings) toJSON;
  in {
    # Verify dir on first launch; net.imput.helium is the expected profile dir.
    xdg.config.files."net.imput.helium/Default/Preferences".text = toJSON preferences;
  };
}
