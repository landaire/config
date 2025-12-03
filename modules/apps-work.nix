{pkgs, ...}: {
  # Additional packages for work hosts
  environment.systemPackages = with pkgs; [
    # Work-specific CLI tools can go here
    # For now, just the essentials from common
  ];

  homebrew = {
    # Work-specific taps (if needed)
    taps = [
    ];

    # Work-specific brews (if needed)
    brews = [
      # Add any work-specific build tools here
    ];

    # Work-specific casks (minimal set)
    casks = [
      # Add any work-required apps here
      # e.g., "slack" if required by work
    ];

    # No Mac App Store apps for work
    masApps = {
    };
  };
}
