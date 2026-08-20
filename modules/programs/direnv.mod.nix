{
  # programs.direnv (hjem-rum) installs the direnv package itself, and the
  # nix-direnv integration pulls its direnvrc, so no explicit `packages` here
  # (an explicit pkgs.direnv would collide with rum's in a single buildEnv).
  flake.homeModules.direnv = {
    programs.direnv = {
      enable = true;

      integrations.nix-direnv.enable = true;
      integrations.nushell.enable = true;
    };
  };
}
