{
  flake.homeModules.nushell = { config, ... }: {
    programs.nushell = {
      enable = true;

      extraConfig = /* nu */ ''
        # cargo install puts binaries in $CARGO_HOME/bin (see use-xdg-dirs).
        $env.PATH = $env.PATH | prepend "${config.xdg.data.directory}/cargo/bin"

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
        filesize.unit = "binary";
        cursor_shape = {
          emacs = "blink_line";
          vi_insert = "blink_line";
          vi_normal = "blink_block";
        };
      };
    };
  };
}
