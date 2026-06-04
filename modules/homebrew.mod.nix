{ inputs, ... }:
{
  flake.darwinModules.homebrew =
    { config, lib, ... }:
    let
      inherit (lib.lists) singleton;
    in
    {
      imports = singleton inputs.nix-homebrew.darwinModules.nix-homebrew;

      homebrew.enable = true;
      homebrew.onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "zap";
      };

      nix-homebrew = {
        enable = true;
        user = config.system.primaryUser;

        taps."homebrew/homebrew-core" = inputs.homebrew-core;
        taps."homebrew/homebrew-cask" = inputs.homebrew-cask;

        mutableTaps = false;
      };
    };
}
