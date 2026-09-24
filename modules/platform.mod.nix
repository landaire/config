{
  flake.darwinModules.platform = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 6;
  };

  flake.nixosModules.platform = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "26.05";
  };
}
