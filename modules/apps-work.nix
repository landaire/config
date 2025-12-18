{pkgs, ...}: {
  # Additional packages for work hosts
  environment.systemPackages = with pkgs; [
    # Work-specific CLI tools can go here
    # For now, just the essentials from common
  ];

  homebrew = {
    taps = [
    ];

    brews = [
    ];

    casks = [
    ];

    masApps = {
    };
  };
}
