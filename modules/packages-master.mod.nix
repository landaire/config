{ inputs, ... }:
{
  # Applies the master overlay to every darwin host (attached via darwinModules).
  flake.darwinModules.master-packages = {
    nixpkgs.overlays = [ (import ../overlays/master.nix inputs) ];
  };
}
