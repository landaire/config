{
  flake.darwinModules.shells =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;

      environment.shells = [
        pkgs.zsh
        pkgs.nushell
      ];
    };
}
