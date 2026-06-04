{
  flake.darwinModules.bootstrap = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 6;
  };
}
