{
  flake.homeModules.helix =
    { pkgs, ... }:
    {
      packages = [
        pkgs.helix
        pkgs.taplo
      ];

      xdg.config.files."helix/config.toml".generator = pkgs.writers.writeTOML "helix-config.toml";
      xdg.config.files."helix/config.toml".value = {
        theme = "dark_plus";

        editor.rulers = [ 100 ];
        editor.lsp.display-inlay-hints = true;
        editor.end-of-line-diagnostics = "hint";
        editor.inline-diagnostics.cursor-line = "warning";
      };

      xdg.config.files."helix/languages.toml".generator =
        pkgs.writers.writeTOML "helix-languages.toml";
      xdg.config.files."helix/languages.toml".value = {
        language = [
          {
            name = "nix";
            language-servers = [ "nil" ];
            auto-format = true;
          }
        ];

        language-server.nil.config.nil.formatting.command = [
          "alejandra"
          "--quiet"
          "--"
        ];

        language-server.rust-analyzer.config = {
          check.command = "clippy";
          cargo.features = "all";
          rust.analyzerTargetDir = true;
          rustfmt.extraArgs = [ "+nightly" ];
        };
      };
    };
}
