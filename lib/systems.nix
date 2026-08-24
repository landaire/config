{ lib, self, ... }:
let
  inherit (lib.attrsets) attrValues removeAttrs;
  inherit (lib.lists) concatMap filter singleton;

  # Home modules that must NOT attach on linux (reference osConfig or darwin paths).
  darwinOnlyHome = [ "shadow-xcode" "helium" "shell-env-darwin" "hammerspoon" ];
  # Home modules that must NOT attach on darwin (linux-only concerns).
  linuxOnlyHome = [ "shell-env-linux" "helium-linux" "apps" "audio" ];
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
        overlays = [ (import ../overlays/master.nix self.inputs) ];
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

      manifest = {
        version = 3;
        inherit files;
      };

      # hjem standalone `switch` only nix-EVALs the manifest; it never builds the
      # source derivations, and smfh silently skips any file whose source store
      # path is not realized. Our sources are generated derivations
      # (writeTOML/writeText/...), so we build the manifest as a derivation that
      # takes every source as an input and hand hjem the built file via
      # `--manifest`. Realizing this (e.g. as part of the switch app's closure)
      # realizes every source into the store, so activation actually links them.
      sourceDrvs =
        fileSets
        |> concatMap (
          fs: fs |> attrValues |> filter (f: f.enable && f.source != null) |> map (f: f.source)
        );
      manifestFile = pkgs.runCommand "${hostName}-manifest.json" {
        srcs = sourceDrvs;
        value = builtins.toJSON manifest;
        passAsFile = [ "value" ];
      } ''cp "$valuePath" "$out"'';
    in
    {
      flake.hjemConfigurations.${hostName} = {
        # `manifest` is the eval-only value; `manifestFile` is the built file
        # (sources realized) that the switch passes to `hjem ... --manifest`.
        inherit manifest manifestFile eval pkgs;
      };

      flake.packages.${system} = {
        "${hostName}-tools" = pkgs.buildEnv {
          name = "${hostName}-tools";
          paths = cfg.packages;
        };
        "${hostName}-manifest" = manifestFile;
      };
    };
}
