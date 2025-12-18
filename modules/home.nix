{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  #home.username = "${username}";
  #home.homeDirectory = "/Users/${username}";

  xdg.enable = true;

  home.packages = [];

  xdg.configFile."nvim/init.vim".source = ../dotfiles/nvim/init.vim;
  xdg.configFile."jj/config.toml".source = ../dotfiles/jj/config.toml;
  xdg.configFile."wezterm/wezterm.lua".source = ../dotfiles/wezterm/wezterm.lua;
  xdg.configFile."rustfmt/rustfmt.toml".source = ../dotfiles/rustfmt/rustfmt.toml;

  home.file.".zshrc".source = ../dotfiles/.zshrc;
  home.file.".zprofile".source = ../dotfiles/.zprofile;
  home.file.".profile".source = ../dotfiles/.profile;
  home.file.".cargo/config.toml".text = ''
    [build]
    build-dir = "${config.home.homeDirectory}/.cargo/build"
  '';

  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    settings = {
      default-root-container-layout = "accordion";
      gaps = {
        outer.left = 8;
        outer.bottom = 8;
        outer.top = 8;
        outer.right = 8;
      };
      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-b = "workspace B";
        alt-c = "workspace C";
        alt-d = "workspace D";
        alt-e = "workspace E";
        alt-f = "workspace F";
        alt-g = "workspace G";
        alt-i = "workspace I";
        alt-m = "workspace M";
        alt-n = "workspace N";
        alt-o = "workspace O";
        alt-p = "workspace P";
        alt-q = "workspace Q";
        alt-r = "workspace R";
        alt-s = "workspace S";
        alt-t = "workspace T";
        alt-u = "workspace U";
        alt-v = "workspace V";
        alt-w = "workspace W";
        alt-x = "workspace X";
        alt-y = "workspace Y";
        alt-z = "workspace Z";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-b = "move-node-to-workspace B";
        alt-shift-c = "move-node-to-workspace C";
        alt-shift-d = "move-node-to-workspace D";
        alt-shift-e = "move-node-to-workspace E";
        alt-shift-f = "move-node-to-workspace F";
        alt-shift-g = "move-node-to-workspace G";
        alt-shift-i = "move-node-to-workspace I";
        alt-shift-m = "move-node-to-workspace M";
        alt-shift-n = "move-node-to-workspace N";
        alt-shift-o = "move-node-to-workspace O";
        alt-shift-p = "move-node-to-workspace P";
        alt-shift-q = "move-node-to-workspace Q";
        alt-shift-r = "move-node-to-workspace R";
        alt-shift-s = "move-node-to-workspace S";
        alt-shift-t = "move-node-to-workspace T";
        alt-shift-u = "move-node-to-workspace U";
        alt-shift-v = "move-node-to-workspace V";
        alt-shift-w = "move-node-to-workspace W";
        alt-shift-x = "move-node-to-workspace X";
        alt-shift-y = "move-node-to-workspace Y";
        alt-shift-z = "move-node-to-workspace Z";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
        alt-shift-semicolon = "mode service";
      };
      mode.service.binding = {
        esc = [
          "reload-config"
          "mode main"
        ];
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        backspace = [
          "close-all-windows-but-current"
          "mode main"
        ];

        alt-shift-h = [
          "join-with left"
          "mode main"
        ];
        alt-shift-j = [
          "join-with down"
          "mode main"
        ];
        alt-shift-k = [
          "join-with up"
          "mode main"
        ];
        alt-shift-l = [
          "join-with right"
          "mode main"
        ];
      };
      on-window-detected = [
        {
          "if".app-id = "com.github.wez.wezterm";
          run = "move-node-to-workspace T";
        }
        {
          "if".app-id = "dev.zed.Zed";
          run = "move-node-to-workspace Z";
        }
        {
          "if".app-id = "ru.keepcoder.Telegram";
          run = "move-node-to-workspace M";
        }
        {
          "if".app-id = "com.apple.Messages";
          run = "move-node-to-workspace M";
        }
        {
          "if".app-id = "org.whispersystems.signal-desktop";
          run = "move-node-to-workspace M";
        }
      ];
    };
  };

  programs.nushell = {
    enable = true;
    extraConfig = ''
      ^ssh-agent -c
       | lines
       | first 2
       | parse "setenv {name} {value};"
       | transpose -r
       | into record
       | load-env
    '';
    settings = {
      show_banner = false;
      edit_mode = "vi";
      filesize = {
        unit = "binary";
      };
      cursor_shape = {
        emacs = "blink_line";
        vi_insert = "blink_line";
        vi_normal = "blink_block";
      };
    };
  };

  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      style = "compact";
    };
  };

  programs.zoxide = {
    enable = true;
    enableNushellIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      directory = {
        fish_style_pwd_dir_length = 1;
      };
      time = {
        disabled = false;
        format = "[\\[ $time \\]]($style) ";
      };
      gcloud = {
        disabled = true;
      };
    };
  };

  programs.zed-editor = {
    enable = true;
    extensions = ["nix" "toml" "rust"];
    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      theme = "Ayu Dark";
      ui_font_size = 12;
      buffer_font_size = 12;
      vim_mode = true;
      buffer_font_family = "Berkeley Mono";
      inlay_hints = {
        enabled = true;
      };
      show_edit_predictions = false;
      minimap = {
        show = "always";
      };
      diagnostics = {
        inline = {
          enabled = true;
        };
      };
      format_on_save = "on";
      languages = {
        "Nix" = {
          "language_servers" = ["!nixd" "nil"];
        };
      };
      lsp = {
        nil = {
          initialization_options = {
            formatting = {
              command = [
                "alejandra"
                "--quiet"
                "--"
              ];
            };
          };
        };

        rust-analyzer = {
          initialization_options = {
            check = {
              command = "clippy";
            };
            cargo = {
              features = "all";
            };
            rust = {
              analyzerTargetDir = true;
            };
            rustfmt = {
              extraArgs = ["+nightly"];
            };
          };
        };
      };
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
