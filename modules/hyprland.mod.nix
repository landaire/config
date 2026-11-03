{
  flake.homeModules.hyprland = {
    xdg.config.files."fuzzel".source = ../dotfiles/fuzzel;
    xdg.config.files."hypr".source = ../dotfiles/hypr;
    xdg.config.files."mako".source = ../dotfiles/mako;
    xdg.config.files."waybar".source = ../dotfiles/waybar;
    xdg.config.files."systemd/user/hyprland-session.target".text = ''
      [Unit]
      Description=Hyprland session
      BindsTo=graphical-session.target
      Wants=graphical-session-pre.target
      After=graphical-session-pre.target
      PropagatesStopTo=graphical-session.target
    '';
  };
}
