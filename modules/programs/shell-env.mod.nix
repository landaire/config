{
  # COMMON: env + aliases wanted on every host (nushell is the interactive shell).
  flake.homeModules.shell-env = {
    environment.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    };

    programs.nushell.aliases = {
      vim = "nvim";
      lsl = "eza -lah";
      lst = "eza -la --sort=modified";
      gc = "git commit -m";
    };
  };

  # DARWIN: homebrew on PATH (replaces the deleted .zprofile brew shellenv),
  # and the zsh login stub (replaces the deleted .zshrc) that hands off to nushell.
  flake.homeModules.shell-env-darwin =
    { config, ... }:
    {
      programs.nushell.extraConfig = /* nu */ ''
        $env.PATH = $env.PATH | prepend ["/opt/homebrew/bin" "/opt/homebrew/sbin"]
      '';

      files.".zshrc".source = ../../dotfiles/zshrc-stub.zsh;
    };

  # LINUX: KDE/Wayland clipboard + disk listing.
  flake.homeModules.shell-env-linux = {
    programs.nushell.aliases = {
      tcopy = "wl-copy";
      disks = "lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID";
    };
  };
}
