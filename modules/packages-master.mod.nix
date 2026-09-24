{ inputs, ... }:
{
  # Applies the master overlay to every host (attached via commonModules).
  flake.commonModules.master-packages = {
    nixpkgs.overlays = [
      (import ../overlays/master.nix inputs)
      (import ../overlays/reindeer.nix)
    ];
  };
}
