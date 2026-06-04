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

            # System user account (required for system.primaryUser derivation).
            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
            };

            # hjem (darwinModules.home) supplies `home`; attach every home module
            # to this user and create the account.
            home.users.${username} = { };
            home.extraModules = attrValues self.homeModules;
          };
      };
    };
}
