{
  flake.homeModules.nushell = {
    programs.nushell = {
      enable = true;

      extraConfig = /* nu */ ''
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
