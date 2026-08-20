{ lib, self, ... }:
let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) concatMap filter singleton;

  # Home modules that must NOT attach on linux (reference osConfig or darwin paths).
  darwinOnlyHome = [ "shadow-xcode" "helium" "shell-env-darwin" "hammerspoon" ];
  # Home modules that must NOT attach on darwin (linux-only concerns).
  linuxOnlyHome = [ "shell-env-linux" "helium-linux" "apps" ];
in
{
  # darwinSystem hostName { username, useremail, profile } -> registers
  # flake.darwinConfigurations.<hostName>. `profile` is "personal" | "work".
  darwinSystem =
    hostName:
    {
      username,
      useremail,
      profile,
    }:
    {
      flake.darwinConfigurations.${hostName} = self.inputs.nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit
            lib
            self
            username
            useremail
            hostName
            profile
            ;
          inputs = self.inputs;
          isPersonal = profile == "personal";
        };

        modules =
          attrValues self.commonModules
          ++ attrValues self.darwinModules
          ++ singleton {
            networking.hostName = hostName;
            networking.computerName = hostName;
            system.defaults.smb.NetBIOSName = hostName;

            nix.settings.trusted-users = [ "root" username ];

            system.configurationRevision = self.rev or self.dirtyRev or null;

            # System user account. REQUIRED and load-bearing: primary-user.mod.nix
            # derives system.primaryUser from a /Users/-homed user, AND hjem's
            # darwin base derives each home user's `directory` from this
            # users.users.<name>.home. Removing this breaks config.directory
            # (and the XDG vars in modules/home.mod.nix) -- do not delete.
            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
              description = username;
            };

            # hjem (darwinModules.home) supplies `home`; an entry here enables the
            # user (enable defaults true) and attaches every home module to them.
            home.users.${username} = { };
            home.extraModules = attrValues (removeAttrs self.homeModules linuxOnlyHome);
          };
      };
    };

  # hjemSystem hostName { username, useremail, profile } -> registers
  # flake.hjemConfigurations.<hostName> (v3 manifest) + a tools package env,
  # for hjem's standalone CLI on non-NixOS Linux (Bazzite).
  hjemSystem =
    hostName:
    {
      username,
      useremail,
      profile,
    }:
    let
      system = "x86_64-linux";
      hjemSrc = self.inputs.hjem;
      isPersonal = profile == "personal";

      # Standalone has no nixpkgs module; apply the unfree allowlist at import.
      allowedUnfree = [
        "claude-code"
        "google-cloud-sdk"
        "dotnet-sdk"
      ];
      pkgs = import self.inputs.nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowedUnfree;
      };

      hjem-lib = import (hjemSrc + "/lib.nix") { inherit lib pkgs; };
      directory = "/home/${username}";

      eval = lib.evalModules {
        class = "hjem";
        specialArgs = {
          inherit
            lib
            pkgs
            username
            useremail
            isPersonal
            ;
          inputs = self.inputs;
        };
        modules =
          [ (hjemSrc + "/modules/common/user.nix") ]
          ++ [ self.inputs.hjem-rum.hjemModules.hjem-rum ]
          ++ attrValues (removeAttrs self.homeModules darwinOnlyHome)
          ++ [
            {
              inherit directory;
              user = username;
              clobberFiles = true;
              _module.args.name = username;
            }
          ];
      };

      cfg = eval.config;
      fileSets = [
        cfg.files
        cfg.xdg.cache.files
        cfg.xdg.config.files
        cfg.xdg.data.files
        cfg.xdg.state.files
      ];
      files =
        fileSets
        |> concatMap (
          fs: fs |> attrValues |> filter (f: f.enable) |> map hjem-lib.fileToJson
        );
    in
    {
      flake.hjemConfigurations.${hostName} = {
        manifest = {
          version = 3;
          inherit files;
        };
        # Retained for the switch app and on-device debugging.
        inherit eval pkgs;
      };

      flake.packages.${system}."${hostName}-tools" = pkgs.buildEnv {
        name = "${hostName}-tools";
        paths = cfg.packages;
      };
    };
}
