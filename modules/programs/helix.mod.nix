{
  flake.homeModules.helix =
    { pkgs, ... }:
    let
      # Per-user private directory. $PPID is the helix process, so each instance gets its own file.
      yaziChooser = "\"\${XDG_RUNTIME_DIR:-\${TMPDIR:-/tmp}}/helix-yazi-$PPID\"";
    in
    {
      packages = [
        pkgs.helix
        pkgs.taplo
      ];

      xdg.config.files."helix/config.toml".generator = pkgs.writers.writeTOML "helix-config.toml";
      xdg.config.files."helix/config.toml".value = {
        theme = "dark_plus";

        editor.rulers = [ 100 ];
        editor.cursor-shape.insert = "bar";
        editor.lsp.display-inlay-hints = true;
        editor.end-of-line-diagnostics = "hint";
        editor.inline-diagnostics.cursor-line = "warning";

        # Ctrl-y opens yazi in the working directory as a file picker and opens the first chosen
        # file. The buffer path is not passed to yazi because helix splices it into shell source
        # unescaped. The printf and the mouse toggle restore terminal modes that yazi resets.
        keys.normal.C-y = [
          ":sh rm -f ${yaziChooser}"
          ":insert-output yazi --chooser-file=${yaziChooser}"
          ":sh printf '\\033[?1049h\\033[?2004h' > /dev/tty"
          ":open %sh(head -n 1 ${yaziChooser})"
          ":sh rm -f ${yaziChooser}"
          ":redraw"
          ":set mouse false"
          ":set mouse true"
        ];
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
