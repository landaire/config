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
    sendme
    nil
    alejandra
    lazyjj
    nushell
    jujutsu
    zoxide
    just
    atuin
    p7zip
    bat
    bacon
    curl
    wget
    crabz
    diff-so-fancy
    difftastic
    dog
    fzf
    git-cliff
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
    yt-dlp
    uv
    starship
    sccache
    ripgrep
    protobuf
    kondo
    delta
    claude-code
    fcp
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true; # Fetch the newest stable branch of Homebrew's git repo
      upgrade = true; # Upgrade outdated casks, formulae, and App Store apps
      # 'zap': uninstalls all formulae(and related files) not listed in the generated Brewfile
      cleanup = "zap";
    };

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
