{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  # List all .otf font files (these are sops-encrypted)
  fontFiles = builtins.filter 
    (f: lib.hasSuffix ".otf" f) 
    (builtins.attrNames (builtins.readDir ../secrets/fonts/BerkeleyMono));
  
  # Generate sops secrets for each font
  fontSecrets = builtins.listToAttrs (map (fontFile: {
    name = "fonts/${lib.removeSuffix ".otf" fontFile}";
    value = {
      sopsFile = ../secrets/fonts/BerkeleyMono/${fontFile};
      format = "binary";
      path = "/run/secrets/fonts/${fontFile}";
      owner = username;
    };
  }) fontFiles);
in {
  # Define all font secrets with user ownership
  sops.secrets = fontSecrets;

  # Use home-manager activation to install fonts to user directory
  home-manager.users.${username} = { config, ... }: {
    home.activation.installFonts = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Installing sops-managed fonts to user directory..."
      FONT_DIR="$HOME/Library/Fonts/Berkeley Mono"
      mkdir -p "$FONT_DIR"

      if [ -d /run/secrets/fonts ]; then
        for font in /run/secrets/fonts/*.otf; do
          if [ -f "$font" ]; then
            cp -f "$font" "$FONT_DIR/" && echo "Installed $(basename $font) to user fonts"
          fi
        done
      fi
    '';
  };
}
