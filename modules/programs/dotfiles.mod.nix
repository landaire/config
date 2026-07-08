{
  flake.homeModules.dotfiles = {config, ...}: {
    xdg.config.files."nvim/init.vim".source = ../../dotfiles/nvim/init.vim;
    xdg.config.files."wezterm/wezterm.lua".source = ../../dotfiles/wezterm/wezterm.lua;
    xdg.config.files."rustfmt/rustfmt.toml".source = ../../dotfiles/rustfmt/rustfmt.toml;

    files.".zshrc".source = ../../dotfiles/.zshrc;
    files.".zprofile".source = ../../dotfiles/.zprofile;
    files.".profile".source = ../../dotfiles/.profile;

    # Cargo reads config from $CARGO_HOME, which use-xdg-dirs points at
    # ${config.xdg.data.directory}/cargo. Writing to ~/.cargo would be ignored.
    xdg.data.files."cargo/config.toml".text = ''
      [build]
      build-dir = "${config.xdg.data.directory}/cargo/build"
    '';

    xdg.data.files."claude/CLAUDE.md".source = ../../dotfiles/claude/CLAUDE.md;

    # Claude skills under CLAUDE_CONFIG_DIR (~/.config/claude-code) set by use-xdg-dirs.
    xdg.config.files."claude-code/skills".source = ../../dotfiles/skills;
  };
}
