# Berkeley Mono is licensed, so its files are agenix secrets. A host installs
# them when its host key is among the recipients in secrets/secrets.nix.
{
  flake.darwinModules.fonts =
    {
      config,
      lib,
      hostName,
      username,
      ...
    }:
    let
      inherit (lib.attrsets) attrNames listToAttrs nameValuePair;
      inherit (lib.lists) elem filter;
      inherit (lib.strings) hasPrefix removePrefix removeSuffix;

      keys = import ../keys.nix;
      rules = import ../secrets/secrets.nix;

      hostKey = keys.hosts.${hostName} or null;
      secrets =
        attrNames rules |> filter (name: hasPrefix "fonts/" name && elem hostKey rules.${name}.publicKeys);
      fontDir = "${config.users.users.${username}.home}/Library/Fonts";
    in
    {
      age.secrets = listToAttrs (
        map (
          secret:
          let
            font = secret |> removePrefix "fonts/" |> removeSuffix ".age";
          in
          nameValuePair font {
            file = ../secrets + "/${secret}";
            # A copy, so the fonts do not depend on the agenix ramdisk.
            path = "${fontDir}/${font}";
            symlink = false;
            owner = username;
            group = "staff";
            mode = "0444";
          }
        ) secrets
      );
    };
}
