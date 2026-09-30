# CLI tool lists for workstations and the NixOS build server.
{
  pkgs,
  inputs,
  trunk ? pkgs.trunk,
}:
let
  system = pkgs.stdenv.hostPlatform.system;
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

  # hxy is a desktop hex editor. Keep it on workstation profiles, but do not
  # include it in the headless NixOS server's system profile.
  workstation = [ inputs.hxy.packages.${system}.default ];

  personal = with pkgs; [
    sendme bacon kondo zola asciinema mdbook claude-code codex trunk mergiraf
    opencode dioxus-cli nodejs_26
  ];
}
