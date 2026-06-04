{ lib, self, ... }:
let
  inherit (lib.attrsets) attrValues;
  inherit (lib.lists) singleton;
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

            # System user account. REQUIRED and load-bearing: primary-user.mod.nix
            # derives system.primaryUser from a /Users/-homed user, AND hjem's
            # darwin base derives each home user's `directory` from this
            # users.users.<name>.home. Removing this breaks config.directory
            # (and the XDG vars in modules/home.mod.nix) — do not delete.
            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
            };

            # hjem (darwinModules.home) supplies `home`; an entry here enables the
            # user (enable defaults true) and attaches every home module to them.
            home.users.${username} = { };
            home.extraModules = attrValues self.homeModules;
          };
      };
    };
}
