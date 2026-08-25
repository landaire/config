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

      # Bootstrap the session variables for zsh itself. hjem only *generates*
      # environment.loadEnv ("a POSIX compliant shell script that needs to be
      # sourced where needed") -- it never installs it anywhere. hjem-rum's
      # nushell module also emits them as a `load-env` inside config.nu, but
      # that is circular on darwin: nushell locates config.nu via
      # XDG_CONFIG_HOME, and without it falls back to
      # ~/Library/Application Support/nushell and ignores ~/.config/nushell
      # entirely. .zshenv runs before .zshrc execs nushell, breaking the cycle.
      files.".zshenv".text = ''
        . ${config.environment.loadEnv}
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
