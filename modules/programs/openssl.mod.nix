# pkg-config consumers (Rust's openssl-sys, C builds) locate OpenSSL through
# pkg-config. The active pkg-config is nix's, which searches only the nix store,
# and homebrew's openssl is keg-only and gets removed by homebrew's zap cleanup.
# Provide OpenSSL from nix and point pkg-config at its .pc dir so builds resolve
# it declaratively, independent of homebrew.
{
  flake.homeModules.openssl =
    { pkgs, ... }:
    {
      environment.sessionVariables.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
      packages = [ pkgs.openssl ];
    };
}
