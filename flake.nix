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

    # sops-nix.url = "github:Mic92/sops-nix";
  };

  # flake.nix (outputs fragment)
  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    home-manager,
    # sops-nix,
    ...
  }: let
    system = "aarch64-darwin";
    lib = nixpkgs.lib;

    # Host profiles for conditional module loading
    hostProfiles = {
      salusa = "personal";
      caladan = "personal";
      ix = "personal";
      landerb-mac2 = "work";
    };

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
      ix = {
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
      hostProfile = hostProfiles.${hostname} or "personal";
      isPersonal = hostProfile == "personal";

      # Host-specific modules
      hostModules = [
        ./configuration.nix
        ./modules/host-users.nix
        ./modules/darwin-configuration.nix
        ./modules/apps.nix
        # ./modules/fonts.nix  # Disabled - requires sops-nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak";
          # Use the same home config for all hosts
          home-manager.users.${username} = import ./modules/home.nix;
          home-manager.sharedModules =
            lib.optionals isPersonal [
            ];
          home-manager.extraSpecialArgs = {inherit inputs isPersonal system;};
        }
        {networking.hostName = hostname;}
        # sops-nix.darwinModules.sops
      ];
    in
      nix-darwin.lib.darwinSystem {
        inherit system;
        # Pass through anything you want available inside modules
        specialArgs = inputs // {inherit username useremail hostname hostProfile isPersonal;};
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
