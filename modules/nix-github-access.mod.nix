# Lets Nix fetch private GitHub repositories, such as the poseidon flake input,
# with the token in secrets/radicle-github-token.age. The token reaches Nix
# through a root-only nix.conf fragment written during activation.
{
  flake.nixosModules.nix-github-access =
    { config, ... }:
    let
      tokenConf = "/run/nix/github-access-token.conf";
    in
    {
      age.secrets.nix-github-access-token.file = ../secrets/radicle-github-token.age;

      # `!include` ignores a missing or unreadable file, so evaluation before
      # the first activation and Nix commands run by other users still work.
      # The directory must stay traversable: a permission error on the path
      # itself makes Nix discard all of nix.conf for that user.
      nix.extraOptions = ''
        !include ${tokenConf}
      '';

      system.activationScripts.nix-github-access-token = {
        deps = [ "agenixInstall" ];
        text = ''
          token=${config.age.secrets.nix-github-access-token.path}
          if [ -s "$token" ]; then
            install -d -m 0755 /run/nix
            (umask 077 && printf 'access-tokens = github.com=%s\n' "$(cat "$token")" > ${tokenConf}.tmp)
            mv -f ${tokenConf}.tmp ${tokenConf}
          fi
        '';
      };
    };
}
