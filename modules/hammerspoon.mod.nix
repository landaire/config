{
  flake.darwinModules.hammerspoon = {
    system.defaults.CustomSystemPreferences."org.hammerspoon.Hammerspoon".MJConfigFile =
      "~/.config/hammerspoon/init.lua";

    homebrew.casks = [ "hammerspoon" ];
  };

  flake.homeModules.hammerspoon =
    { pkgs, ... }:
    let
      spoonInstall = pkgs.fetchzip {
        url = "https://github.com/Hammerspoon/Spoons/raw/e5b871250346c3fe93bac0d431fc75f6f0e2f92a/Spoons/SpoonInstall.spoon.zip";
        sha256 = "sha256-3f0d4znNuwZPyqKHbZZDlZ3gsuaiobhHPsefGIcpCSE=";
      };

      paperWM = pkgs.fetchgit {
        url = "https://github.com/mogenson/PaperWM.spoon";
        rev = "41c796a7edd78575aa71b77295672aa0a4a2c3ea";
        sha256 = "sha256-u6ZmrCbEUzkQZyGv61DiErdiXR7IPn7cHyuDa9qYzGc=";
      };
    in
    {
      xdg.config.files."hammerspoon/Spoons/SpoonInstall.spoon".source = spoonInstall;
      xdg.config.files."hammerspoon/Spoons/PaperWM.spoon".source = paperWM;
      xdg.config.files."hammerspoon/init.lua".source = ../dotfiles/hammerspoon/init.lua;
    };
}
