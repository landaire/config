{
  description = "Darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # darwin = {
    #   url = "github:nix-darwin/nix-darwin/master";
    #   inputs.nixpkgs.follows = "darwin";
    # };

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # flake.nix (outputs fragment)
  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "aarch64-darwin";

    # Host-specific configuration
    hostConfigs = {
      salusa = {
        username = "lander";
        useremail = "landaire@proton.me";
      };
      caladan = {
        username = "lander";
        useremail = "landaire@proton.me";
      };
      landerb-mac2 = {
        username = "landerb";
        useremail = "landerb@meta.com";
      };
    };

    # Helper to build one darwin system per hostname
    mkDarwin = hostname: let
      # Get host-specific config, with fallback defaults
      hostConfig =
        hostConfigs.${
          hostname
        } or {
          username = "lander";
          useremail = "landaire@proton.me";
        };
      username = hostConfig.username;
      useremail = hostConfig.useremail;

      # Host-specific modules
      hostModules = [
        ./configuration.nix
        ./modules/host-users.nix
        ./modules/system.nix
        ./modules/apps.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = ".bak";
          # Use the same home config for all hosts
          home-manager.users.${username} = import ./modules/home.nix;
          # (Optionally: home-manager.extraSpecialArgs = { ... };)
        }
        {networking.hostName = hostname;}
      ];
    in
      nix-darwin.lib.darwinSystem {
        inherit system;
        # Pass through anything you want available inside modules
        specialArgs = inputs // {inherit username useremail hostname;};
        modules = hostModules;
      };

    # Get list of all defined hosts
    hosts = builtins.attrNames hostConfigs;

    # Turn the host list into an attrset for darwinConfigurations
    mkMap = names:
      builtins.listToAttrs (map (n: {
          name = n;
          value = mkDarwin n;
        })
        names);
  in {
    darwinConfigurations = mkMap hosts;
  };
}
