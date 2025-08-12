{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # darwin = {
    #   url = "github:nix-darwin/nix-darwin/master";
    #   inputs.nixpkgs.follows = "darwin";
    # };

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
  }: let
    username = "lander";
    useremail = "landaire@proton.me";
    system = "aarch64-darwin"; # aarch64-darwin or x86_64-darwin
    hostname = "salusa";

    specialArgs =
      inputs
      // {
        inherit username useremail hostname;
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#salusa
    darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        ./configuration.nix
        ./modules/host-users.nix
        ./modules/system.nix
        ./modules/apps.nix
      ];
    };
  };
}
