# Poseidon, the World of Warships Discord and Twitch bot, in three NixOS
# containers: the chat gateway, the agent, and llama-server. The module comes
# from the poseidon flake input; a host opts in with `services.poseidon.enable`.
#
# The gateway reads the Discord token from secrets/poseidon-discord-token.age
# and the Twitch client secret from secrets/poseidon-twitch-client-secret.age.
{ inputs, ... }:
{
  flake.nixosModules.poseidon =
    { config, lib, ... }:
    let
      # Mounted read-only into the gateway container.
      secretsDir = "/var/lib/secrets/poseidon";
    in
    {
      imports = [ inputs.poseidon.nixosModules.default ];

      config = lib.mkIf config.services.poseidon.enable {
        services.poseidon = {
          discord = {
            tokenFile = config.age.secrets.poseidon-discord-token.path;
            bugs = {
              guild = 1184019275221053530;
              channel = 1480105315461759147;
              trackers = [ 242334789540118528 ];
            };
            review.channel = 1568209127552065657;
            feedback.channel = 1568386911494742127;
          };

          twitch = {
            enable = true;
            clientId = "msvy8jcrxpkpxk6fru0yrm0v8rg9yk";
            clientSecretFile = config.age.secrets.poseidon-twitch-client-secret.path;
            botLogin = "AdalBotSchneider";
            channels = [
              "g4nng"
              "bfk_fer1yfe"
              "trenlass"
              "flamuu"
              "sepbtw"
              "john_the_ruthless"
              {
                login = "landaire";
                introduce = false;
              }
            ];
          };

          # Thinks only for rankings, recommendations, multi-subject questions
          # and follow-ups that dispute an answer.
          agentSettings.llm.thinking = "by_subject";

          # Records answered questions for the thinking on/off comparison.
          questionLog.until = "2026-11-10T02:11:25Z";
        };

        # Copied rather than symlinked into /run/agenix, which the container
        # cannot see; the container bind-mounts the directory.
        age.secrets.poseidon-discord-token = {
          file = ../secrets/poseidon-discord-token.age;
          path = "${secretsDir}/discord-token";
          symlink = false;
        };
        age.secrets.poseidon-twitch-client-secret = {
          file = ../secrets/poseidon-twitch-client-secret.age;
          path = "${secretsDir}/twitch-client-secret";
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
