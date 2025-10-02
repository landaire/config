{
  pkgs,
  username,
  ...
}: {
  ##########################################################################
  #
  #  Install all apps and packages here.
  #
  # TODO Fell free to modify this file to fit your needs.
  #
  ##########################################################################

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    # General CLI tools
    fd
    git
    tealdeer
    sendme
    jujutsu
    fcp
    ripgrep
    crabz
    bat
    bacon
    curl
    wget
    p7zip
    kondo
    yt-dlp
    dogdns

    # Shell stuff
    atuin
    fzf
    zoxide
    starship

    # Programming tools
    git-cliff
    nil
    alejandra
    lazyjj
    nushell
    just
    diff-so-fancy
    difftastic
    helix
    hexyl
    httpie
    htop
    bottom
    hyperfine
    jaq
    neovim
    mise
    mdbook
    uv
    sccache
    protobuf
    delta
    claude-code
    helix
    trunk
    mergiraf
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

    taps = [
      "nikitabobko/tap"
    ];

    brews = [
      "twitch-cli"
    ];

    casks = [
      "iina"
      "audacity"
      "chatterino"
      "DevUtils"
      "gcloud-cli"
      "raycast"
      "handbrake-app"
      "hiddenbar"
      "macfuse"
      "wezterm"
      "zed"
      "speedcrunch"
      "keycastr"
      "keepingyouawake"
    ];
  };
}
