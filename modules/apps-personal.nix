{pkgs, ...}: {
  # Additional packages for personal hosts
  environment.systemPackages = with pkgs; [
    # Personal-specific CLI tools
    sendme
    bacon
    kondo
    zola
    asciinema
    mdbook
    claude-code
    trunk
    mergiraf
  ];

  homebrew = {
    # Additional taps for personal use
    taps = [
      "nikitabobko/tap"
    ];

    # Additional brews for personal use
    brews = [
      "twitch-cli"
      "dylibbundler"
    ];

    # Personal-use casks
    casks = [
      "tailscale-app"
      "iina"
      "audacity"
      "chatterino"
      "DevUtils"
      "gcloud-cli"
      "handbrake-app"
      "macfuse"
      "keycastr"
      "dotnet-sdk"
      "spotify"
      "cleanshot"
      "proton-mail"
      "proton-pass"
      "proton-drive"
      "protonvpn"
      "obsidian"
      "discord"
      "signal"
      "telegram"
      "claude"
      "nikitabobko/tap/aerospace"
      "transmit"
      "glide"
    ];

    # Mac App Store apps for personal use
    masApps = {
      "WhatsApp" = 310633997;
      "Peek" = 1554235898;
      "Windows" = 1295203466;
    };
  };
}
