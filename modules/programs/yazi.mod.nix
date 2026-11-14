{
  flake.homeModules.yazi =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;
    in
    {
      packages = [ pkgs.yazi ];

      xdg.config.files."yazi/yazi.toml".generator = pkgs.writers.writeTOML "yazi.toml";
      xdg.config.files."yazi/yazi.toml".value = {
        opener.edit = [
          {
            run = "${getExe pkgs.helix} %s";
            desc = "helix";
            block = true;
            for = "unix";
          }
        ];
      };
    };
}
