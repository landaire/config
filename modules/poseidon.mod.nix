# Poseidon, the World of Warships Discord bot, and its llama-server backend in
# two NixOS containers. The module comes from the poseidon flake input; a host
# opts in with `services.poseidon.enable`.
#
# The bot reads its Discord token from secrets/poseidon-discord-token.age.
{ inputs, ... }:
{
  flake.nixosModules.poseidon =
    { config, lib, ... }:
    let
      secretsDir = "/var/lib/secrets/poseidon";
    in
    {
      imports = [ inputs.poseidon.nixosModules.default ];

      config = lib.mkIf config.services.poseidon.enable {
        services.poseidon.discordTokenFile = config.age.secrets.poseidon-discord-token.path;

        # Copied rather than symlinked into /run/agenix, which the container
        # cannot see; the container bind-mounts the directory.
        age.secrets.poseidon-discord-token = {
          file = ../secrets/poseidon-discord-token.age;
          path = "${secretsDir}/discord-token";
          symlink = false;
        };

        # Serves the CUDA build of llama-cpp.
        nix.settings.substituters = [ "https://cache.nixos-cuda.org" ];
        nix.settings.trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };
    };
}
