# CLI tool lists for workstations and the NixOS build server.
{
  pkgs,
  inputs,
  trunk ? pkgs.trunk,
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  steamroom = pkgs.rustPlatform.buildRustPackage {
    pname = "steamroom";
    version = "unstable";
    src = inputs.steamroom;
    cargoLock.lockFile = inputs.steamroom + "/Cargo.lock";
    cargoBuildFlags = [
      "--package"
      "steamroom-cli"
      "--bin"
      "steamroom"
    ];
    cargoTestFlags = [
      "--package"
      "steamroom-cli"
      "--bin"
      "steamroom"
    ];
    meta = {
      description = "Utilities for interacting with Steam APIs";
      homepage = "https://github.com/landaire/steamroom";
      license = with pkgs.lib.licenses; [ mit asl20 ];
      mainProgram = "steamroom";
      platforms = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    };
  };
  zed = pkgs.writeShellScriptBin "zed" ''
    exec flatpak run dev.zed.Zed "$@"
  '';
in
{
  common = with pkgs; [
    nh fd git tealdeer watchman curl wget p7zip yt-dlp doggo mise procs sd
    gh hexyl eza ffmpeg imagemagick python3 rage crabz fzf git-cliff nil alejandra
    just httpie htop bottom hyperfine jaq neovim uv sccache protobuf delta rustup
    zellij mosh devenv
    # former homebrew brews (cross-platform):
    cmake ninja pkg-config cargo-binstall
    # build toolchain for buck2 projects:
    buck2 reindeer
    # gcloud + dotnet (were casks):
    google-cloud-sdk dotnet-sdk
    # oh-my-pi
    omp
  ];

  # Desktop tools shared by macOS and Linux workstations. Linux uses a wrapper
  # because Flatpak exports Zed as dev.zed.Zed rather than zed.
  workstation =
    [
      steamroom
      inputs.hxy.packages.${system}.default
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ zed ];

  personal = with pkgs; [
    sendme bacon kondo zola asciinema mdbook claude-code codex trunk mergiraf
    opencode dioxus-cli nodejs_26
  ];
}
