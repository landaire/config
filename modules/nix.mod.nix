{
  flake.darwinModules.nix =
    { lib, ... }:
    let
      inherit (lib.modules) mkDefault;
    in
    {
      # NIX SETTINGS
      nix.settings.experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];
      nix.settings.download-buffer-size = 524288000; # 500 MiB

      # BINARY CACHES
      nix.settings.substituters = [
        "https://cache.nixos.org/"
        "https://cache.garnix.io/"
        "https://nix-community.cachix.org/"
      ];
      nix.settings.trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      # GARBAGE COLLECTION
      nix.gc.automatic = mkDefault true;
      nix.gc.options = mkDefault "--delete-older-than 7d";
    };
}
