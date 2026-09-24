{
  flake.darwinModules.sudo = {
    security.pam.services.sudo_local = {
      enable = true;
      touchIdAuth = true;
    };

    security.sudo.extraConfig = /* sudoers */ ''
      Defaults lecture = never
      Defaults pwfeedback
      Defaults env_keep += "EDITOR PATH"
    '';
  };

  # No TouchID on linux. wheel is passwordless because the only way in is an
  # ssh key; the root password exists solely as a console fallback.
  flake.nixosModules.sudo = {
    security.sudo.wheelNeedsPassword = false;

    security.sudo.extraConfig = /* sudoers */ ''
      Defaults lecture = never
      Defaults env_keep += "EDITOR PATH"
    '';
  };
}
