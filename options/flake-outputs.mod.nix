{
  lib,
  moduleLocation,
  ...
}:
let
  inherit (lib.attrsets) mapAttrs optionalAttrs;
  inherit (lib.lists) singleton;
  inherit (lib.options) mkOption;
  inherit (lib.types) deferredModule lazyAttrsOf raw;

  wrap =
    kind: name: value:
    {
      _file = "${toString moduleLocation}#${kind}.${name}";
      imports = singleton value;
    }
    // optionalAttrs (value ? meta) {
      inherit (value) meta;
    };
in
{
  options.flake.darwinConfigurations = mkOption {
    type = lazyAttrsOf raw;
    default = { };
    description = "Darwin system configurations.";
  };

  options.flake.commonModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = { };
    apply = mapAttrs (wrap "commonModules");
    description = "Modules shared between every system type.";
  };

  options.flake.darwinModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = { };
    apply = mapAttrs (wrap "darwinModules");
    description = "Darwin modules.";
  };

  options.flake.homeModules = mkOption {
    type = lazyAttrsOf deferredModule;
    default = { };
    apply = mapAttrs (wrap "homeModules");
    description = "Home (hjem) modules.";
  };
}
