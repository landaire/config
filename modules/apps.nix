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
    fd # find alternative
    git
    tealdeer # tldr -- no bullshit man pages
    sendme # peer-to-peer file transfer
    jujutsu # VCS
    fcp # faster `cp` command
    ripgrep
    crabz # file compression -- like pigz
    bat # `cat` with line numbers
    bacon # background code checker
    curl
    wget
    p7zip # 7z
    kondo # recurisvely clean dependencies / build artifacts in a directory
    yt-dlp # yt-dl but better?
    dogdns # dns queries
    zola # static site generation
    mise # task runner
    procs # better `ps`
    sd # better `sed`
    skim # fzf-ish
    gh # github cli
    hexyl # xxd alternative
    gdb
    eza

    # Shell stuff
    atuin # shell history
    fzf # fuzzy finder
    zoxide # better `cd`
    starship # better prompt
    asciinema # shell recording

    # Programming tools
    git-cliff # git changelog generator
    nil # nix autocomplete
    alejandra
    lazyjj
    nushell # shell
    just # task runner
    difftastic # also better diff view
    httpie # curl-ish
    htop
    bottom # like htop
    hyperfine # benchmarking
    jaq # json query
    neovim
    mise # task runner
    mdbook # markdown book
    uv # python dependency management
    sccache # build caching
    protobuf
    delta # diff viewer
    claude-code
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
      "iina" # kinda like VLC  but better
      "audacity"
      "chatterino" # twitch chat
      "DevUtils"
      "gcloud-cli"
      "raycast" # much, much better spotlight
      "jordanbaird-ice" # like Bartender, but not junk
      "handbrake-app" # video conversion
      "macfuse" # FUSE filesystems
      "wezterm" # good terminal app
      "zed" # good text editor
      "speedcrunch" # calculator
      "keycastr" # display keystrokes on screen
      "keepingyouawake" # keep the mac from going to sleep
      "dotnet"
      "spotify"
      "firefox"
      "tailscale"
      "cleanshot"
    ];
  };
}
