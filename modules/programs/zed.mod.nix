{
  flake.homeModules.zed =
    { lib, ... }:
    let
      inherit (lib.generators) toJSON;
    in
    {
      xdg.config.files."zed/settings.json".generator = toJSON { };
      xdg.config.files."zed/settings.json".value = {
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        theme = "XY-Zed";
        ui_font_size = 12;
        buffer_font_size = 12;
        vim_mode = true;
        buffer_font_family = "Berkeley Mono";
        inlay_hints.enabled = true;
        show_edit_predictions = false;
        minimap.show = "always";
        diagnostics.inline.enabled = true;
        format_on_save = "on";
        auto_install_extensions = {
          nix = true;
          toml = true;
          rust = true;
        };
        languages."Nix".language_servers = [
          "!nixd"
          "nil"
        ];
        lsp = {
          nil.initialization_options.formatting.command = [
            "alejandra"
            "--quiet"
            "--"
          ];
          rust-analyzer.initialization_options = {
            check.command = "clippy";
            cargo.features = "all";
            rust.analyzerTargetDir = true;
            rustfmt.extraArgs = [ "+nightly" ];
          };
        };
      };
    };
}
