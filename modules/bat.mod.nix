{
  flake.homeModules.bat =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.generators) toCliFlagList;
      inherit (lib.meta) getExe;

      batPager = pkgs.writeScriptBin "bat-pager" /* bash */ ''
        #!${getExe pkgs.bash}

        ${getExe pkgs.bat} --plain
      '';
    in
    {
      environment.sessionVariables = {
        MANPAGER = "${getExe batPager}";
        PAGER = "${getExe batPager}";
      };

      programs.nushell.aliases = {
        cat = getExe pkgs.bat;
        less = "${getExe pkgs.bat} --plain";
      };

      packages = [
        pkgs.bat
        pkgs.less
        batPager
      ];

      xdg.config.files."bat/config".generator = toCliFlagList;
      xdg.config.files."bat/config".value = {
        theme = "base16";
        pager = "${getExe pkgs.less} --quit-if-one-screen --quit-on-intr --RAW-CONTROL-CHARS";
      };

      xdg.config.files."bat/themes/base16.tmTheme".text = config.theme.tmTheme;
    };
}
