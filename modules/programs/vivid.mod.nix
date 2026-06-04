{
  flake.homeModules.vivid =
    { lib, pkgs, ... }:
    let
      inherit (lib.meta) getExe;
      inherit (lib.lists) singleton;

      lsColors = pkgs.runCommand "ls_colors.txt" { } ''
        ${getExe pkgs.vivid} generate gruvbox-dark-hard > $out
      '';
    in
    {
      packages = singleton pkgs.vivid;

      extraDependencies = singleton lsColors;

      # FIXME: Decommissioned until nh fixes their remote build
      # (to build with --eval-store auto --store <ssh> rather
      # than evaling drv then uploading it then building remotely)
      #
      # # Yes, IFD. Deal with it.
      # environment.sessionVariables.LS_COLORS = readFile lsColors;
    };
}
