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
}
