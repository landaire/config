{
  config,
  pkgs,
  username,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  #home.username = "${username}";
  #home.homeDirectory = "/Users/${username}";

  xdg.enable = true;

  home.packages = [
  ];

  xdg.configFile."nvim/init.vim".source = ../dotfiles/nvim/init.vim;
  xdg.configFile."jj/config.toml".source = ../dotfiles/jj/config.toml;
  xdg.configFile."wezterm/wezterm.lua".source = ../dotfiles/wezterm/wezterm.lua;
  xdg.configFile."rustfmt/rustfmt.toml".source = ../dotfiles/rustfmt/rustfmt.toml;

  home.file.".zshrc".source = ../dotfiles/.zshrc;
  home.file.".zprofile".source = ../dotfiles/.zprofile;
  home.file.".profile".source = ../dotfiles/.profile;

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
