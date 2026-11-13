{
  inputs,
  lib,
  ...
}: let
  inherit (import ./web-browser/policy.nix {inherit lib inputs;}) policy preferences;
in {
  flake.darwinModules.helium = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib.attrsets) mapAttrsToList removeAttrs;
    inherit (lib.generators) toPlist;
    inherit (lib.meta) getExe;
    inherit (lib.modules) mkAfter;
    inherit (lib.strings) substring toJSON toUpper;
    inherit (lib.shell) asShell;

    identifier = "net.imput.helium.policy";

    # Chromium on macOS reads each extension's policy from its own preference domain.
    payloads =
      [
        (removeAttrs policy ["3rdparty"]
          // {
            PayloadType = "net.imput.helium";
            PayloadIdentifier = "${identifier}.browser";
          })
      ]
      ++ (
        policy."3rdparty".extensions
        |> mapAttrsToList (
          id: extensionPolicy:
            extensionPolicy
            // {
              PayloadType = "net.imput.helium.extensions.${id}";
              PayloadIdentifier = "${identifier}.extensions.${id}";
            }
        )
      )
      |> map (payload: payload // {PayloadVersion = 1;});

    content = {
      PayloadType = "Configuration";
      PayloadVersion = 1;
      PayloadIdentifier = identifier;
      PayloadDisplayName = "Helium";
      PayloadScope = "System";
      PayloadContent = payloads;
    };

    # Content-derived UUIDs, so a policy change produces a profile macOS treats as new.
    contentHash = builtins.hashString "sha256" (toJSON content);
    mkUuid = seed: let
      hash = toUpper (builtins.hashString "sha256" "${contentHash}:${seed}");
    in "${substring 0 8 hash}-${substring 8 4 hash}-${substring 12 4 hash}-${substring 16 4 hash}-${substring 20 12 hash}";

    profileUuid = mkUuid identifier;

    profile = pkgs.writeText "helium.mobileconfig" (toPlist {escape = true;} (content
      // {
        PayloadUUID = profileUuid;
        PayloadContent =
          payloads
          |> map (payload: payload // {PayloadUUID = mkUuid payload.PayloadIdentifier;});
      }));
  in {
    # macOS installs configuration profiles only through System Settings, so a changed
    # profile is opened for approval rather than installed.
    system.activationScripts.postActivation.text = mkAfter (
      asShell pkgs.nushell "helium.nu"
      /*
      nu
      */
      ''
        let user = (ls --long /dev/console | get 0.user)

        # Extract single fields: other profiles may hold data or date values that JSON cannot represent.
        let listing = (^/usr/bin/profiles list -output stdout-xml)
        let extract = {|path| $listing | ^/usr/bin/plutil -extract $path raw -o - - | complete }
        let count = (do $extract _computerlevel)
        let profiles = if $count.exit_code == 0 {
          0..<($count.stdout | str trim | into int) | each {|index|
            let field = {|name| do $extract $"_computerlevel.($index).($name)" | get stdout | str trim }
            {identifier: (do $field ProfileIdentifier), uuid: (do $field ProfileUUID)}
          }
        } else {
          []
        }

        if not ($profiles | any {|p| $p.identifier == "${identifier}" and $p.uuid == "${profileUuid}" }) {
          print "helium policy profile changed, approve it in System Settings > General > Device Management"
          ^/usr/bin/sudo --user $user /usr/bin/open ${profile}
        }

        (^/usr/bin/sudo
          --user $user
          ${getExe pkgs.defaultbrowser} helium)
      ''
    );
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
