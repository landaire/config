{
  flake.darwinModules.bootstrap = {
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 6;

    nix.settings.experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
  };
}
