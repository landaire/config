{pkgs, ...}: {
  # Common packages that should be installed on all hosts
  environment.systemPackages = with pkgs; [
    # Essential CLI tools
    fd
    git
    tealdeer
    jujutsu
    ripgrep
    bat
    curl
    wget
    p7zip
    yt-dlp
    doggo
    mise
    procs
    sd
    skim
    gh
    hexyl
    #gdb
    eza
    ffmpeg
    imagemagick
    python3
    rage
    crabz

    # Shell stuff
    atuin
    fzf
    zoxide
    starship
    atuin

    # Core programming tools
    git-cliff
    nil
    alejandra
    lazyjj
    nushell
    just
    difftastic
    httpie
    htop
    bottom
    hyperfine
    jaq
    neovim
    mise
    uv
    sccache
    protobuf
    delta
    rustup
  ];

  # Common homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };

    # Common brews needed everywhere
    brews = [
      "coreutils"
      "pkg-config"
      "ninja"
      "cmake"
    ];

    # Essential casks for all hosts
    casks = [
      "wezterm"
      "zed"
      "raycast"
      "firefox"
      "jordanbaird-ice"
      "010-editor"
      "monodraw"
      "keepingyouawake"
      "speedcrunch"
      "imhex"
    ];
  };
}
