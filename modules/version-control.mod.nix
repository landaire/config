{
  flake.homeModules.git =
    { lib, useremail, ... }:
    let
      inherit (lib.generators) toGitINI;
    in
    {
      # git itself comes from the shared package list (apps); no explicit
      # package here (gitMinimal would collide with full git in one buildEnv).
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
