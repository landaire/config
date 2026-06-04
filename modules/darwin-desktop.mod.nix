{
  flake.darwinModules.darwin-desktop = {
    # DOCK
    system.defaults.dock = {
      autohide = true;
      show-recents = false;
      orientation = "left";
      mru-spaces = false;
      showhidden = true;
      tilesize = 48;
      magnification = false;
    };

    system.defaults.CustomSystemPreferences."com.apple.dock" = {
      autohide-time-modifier = 0.0;
      autohide-delay = 0.0;
      expose-animation-duration = 0.0;
      launchanim = 0;

      # DISABLE HOT CORNERS
      wvous-tl-corner = 0;
      wvous-tr-corner = 0;
      wvous-bl-corner = 0;
      wvous-br-corner = 0;
    };

    # FINDER
    system.defaults.finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      CreateDesktop = false;
    };

    # TRACKPAD
    system.defaults.trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
    };

    # MENU BAR
    system.defaults.menuExtraClock.Show24Hour = true;
    system.defaults.controlcenter.BatteryShowPercentage = true;

    # GLOBAL
    system.defaults.NSGlobalDomain = {
      "com.apple.sound.beep.feedback" = 0;
      AppleInterfaceStyle = "Dark";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };

    # SCREENSHOTS
    system.defaults.screencapture.location = "~/Downloads/Screenshots";

    # LOGIN WINDOW
    system.defaults.loginwindow.GuestEnabled = false;
  };
}
