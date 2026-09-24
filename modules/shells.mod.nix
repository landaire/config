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

  # Login shell stays POSIX so non-interactive ssh, scp and nixos-rebuild keep
  # working; interactive logins hand off to nushell, matching the darwin hosts.
  flake.nixosModules.shells =
    { pkgs, ... }:
    {
      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;

      # root is the console recovery account and stays on a plain shell, so a
      # broken nushell or zsh config never costs us the last way in.
      users.users.root.shell = pkgs.bashInteractive;

      # Handed off from zshenv, not zprofile: zsh runs its new-user wizard before
      # zprofile when the user has no startup file, which interrupts the login.
      # Guarding on login as well keeps `ssh -t host zsh` a plain zsh escape hatch.
      programs.zsh.shellInit = /* zsh */ ''
        if [[ -o interactive ]] && [[ -o login ]]; then
          exec ${pkgs.nushell}/bin/nu --login
        fi
      '';

      environment.shells = [
        pkgs.zsh
        pkgs.nushell
      ];
    };
}
