{
  pkgs,
  username,
  ...
}:
# Mac system config
{
  security.pam.services.sudo_local.touchIdAuth = true;
  system = {
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "left";
      };

      finder = {
        ShowPathbar = true;
        ShowStatusBar = true;
        CreateDesktop = false;
      };

      trackpad = {
        # tap to click
        Clicking = true;
        # two finger right click
        TrackpadRightClick = true;
      };

      NSGlobalDomain = {
        # Disable audio beeps for volume keys
        "com.apple.sound.beep.feedback" = 0;
        AppleInterfaceStyle = "Dark";
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };

      CustomUserPreferences = {
        "com.apple.screencapture" = {
          location = "~/Desktop/screenshots";
        };
      };

      loginwindow = {
        GuestEnabled = false;
      };
    };
  };
  programs.zsh.enable = true;
  environment.shells = [
    pkgs.zsh
    pkgs.nushell
  ];
}
