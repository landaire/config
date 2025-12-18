{
  config,
  pkgs,
  lib,
  username,
  ...
}: let
  # List all .otf font files (these are sops-encrypted)
  fontFiles =
    builtins.filter
    (f: lib.hasSuffix ".otf" f)
    (builtins.attrNames (builtins.readDir ../secrets/fonts/BerkeleyMono));

  # Generate sops secrets for each font
  fontSecrets = builtins.listToAttrs (map (fontFile: {
      name = "fonts/BerkeleyMono/${fontFile}";
      value = {
        sopsFile = ../secrets/fonts/BerkeleyMono/${fontFile};
        format = "binary";
      };
    })
    fontFiles);
in {
  # Define all font secrets with user ownership
  sops.secrets = fontSecrets;

  # System activation script to install fonts after sops decryption
  system.activationScripts.postActivation.text = ''
    echo "Installing sops-managed fonts to user directory..."

    USER_HOME="/Users/${username}"
    FONT_DIR="$USER_HOME/Library/Fonts"
    SECRETS_FONTS_DIR="/run/secrets/fonts"

    if [ -d $SECRETS_FONTS_DIR ]; then
      echo "Found decrypted fonts, installing..."

      for font_path in "$SECRETS_FONTS_DIR"/*; do
        font_name=$(basename "$font_path")
        # Copy as root (we have permission), then change ownership
        cp -r "$font_path" "$FONT_DIR/$font_name"
        chown -R ${username}:staff "$FONT_DIR/$font_name"
      done

      echo "Font installation complete"
    else
      echo "Warning: /run/secrets/fonts not found yet"
    fi
  '';
}
