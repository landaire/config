{
  flake.homeModules.git =
    { lib, pkgs, useremail, ... }:
    let
      inherit (lib.generators) toGitINI;
      inherit (lib.lists) singleton;
    in
    {
      packages = singleton pkgs.gitMinimal;

      # Identity + base settings. diff.* is added by difftastic.mod.nix (merges).
      xdg.config.files."git/config".generator = toGitINI;
      xdg.config.files."git/config".value = {
        user.name = "Lander Brandt";
        user.email = useremail;

        init.defaultBranch = "main";

        fetch.fsckObjects = true;
        receive.fsckObjects = true;
        transfer.fsckobjects = true;
      };
    };
}
