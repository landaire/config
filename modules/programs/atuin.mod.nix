{
  flake.homeModules.atuin =
    { lib, pkgs, ... }:
    let
      inherit (lib.lists) singleton;
      inherit (lib.meta) getExe;
    in
    {
      packages = singleton pkgs.atuin;

      xdg.config.files."atuin/config.toml".generator = pkgs.writers.writeTOML "atuin-config.toml";
      xdg.config.files."atuin/config.toml".value = {
        style = "compact";
      };

      # NUSHELL INTEGRATION
      programs.nushell.extraConfig = /* nu */ ''
        source ${
          pkgs.runCommand "atuin-nu" { } ''
            export HOME=$(mktemp -d)
            ${getExe pkgs.atuin} init nu --disable-up-arrow > $out
          ''
        }
      '';
    };
}
