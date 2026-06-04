{
  nixConfig = {
    extra-experimental-features = [
      "flakes"
      "nix-command"
      "pipe-operators"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    hjem.url = "github:feel-co/hjem";
    hjem.inputs.nixpkgs.follows = "nixpkgs";
    hjem.inputs.nix-darwin.follows = "nix-darwin";

    hjem-rum.url = "github:snugnug/hjem-rum";
    hjem-rum.inputs.nixpkgs.follows = "nixpkgs";
    hjem-rum.inputs.hjem.follows = "hjem";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    themes.url = "github:RGBCube/ThemeNix";

    helium.url = "github:amaanq/helium-flake";
    helium.inputs.nixpkgs.follows = "nixpkgs";

    ublock = {
      url = "github:imputnet/uBlock";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;

        specialArgs.lib = inputs.nixpkgs.lib.extend (
          final: prev:
          inputs.nixpkgs.lib.recursiveUpdate prev (
            import ./lib {
              lib = final;
              inherit (inputs) self;
            }
          )
        );
      }
      (
        { lib, ... }:
        let
          inherit (lib.filesystem) listFilesRecursive;
          inherit (lib.lists) filter;
          inherit (lib.strings) hasSuffix;
        in
        {
          systems = [ "aarch64-darwin" ];

          imports = filter (hasSuffix ".mod.nix") (listFilesRecursive ./.);
        }
      );
}
