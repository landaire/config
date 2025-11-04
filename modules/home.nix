{
  config,
  pkgs,
  username,
  ...
}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "${username}";
  home.homeDirectory = "/Users/lander";

  home.packages = [
    pkgs.zed-editor
  ];

  programs.zed-editor = {
    enable = true;
    userSettings = {
      theme = "Ayu Dark";
      vim_mode = true;
      buffer_font_familiy = "Berkeley Mono";
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
