{ inputs, ... }:
{
  flake.darwinModules.home = inputs.hjem.darwinModules.hjem;

  flake.commonModules.home =
    { lib, useremail, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkAliasOptionModule;
    in
    {
      imports = singleton <| mkAliasOptionModule [ "home" ] [ "hjem" ];

      home.specialArgs = { inherit lib useremail; };
      home.extraModules = singleton inputs.hjem-rum.hjemModules.hjem-rum;
      home.clobberByDefault = true;
    };

  flake.homeModules.home =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.modules) mkAliasOptionModule;
    in
    {
      imports = singleton <| mkAliasOptionModule [ "programs" ] [ "rum" "programs" ];

      # FORCE XDG ENV VARS (darwin paths).
      environment.sessionVariables = {
        XDG_CACHE_HOME = "${config.directory}/.cache";
        XDG_CONFIG_HOME = "${config.directory}/.config";
        XDG_DATA_HOME = "${config.directory}/.local/share";
        XDG_STATE_HOME = "${config.directory}/.local/state";
      };
    };
}
