# Secrets are age files under secrets/, encrypted to the keys listed in
# secrets/secrets.nix. NixOS hosts decrypt them during activation with their
# SSH host key. Edit one with:
#   cd secrets && nix run 'path:..#agenix' -- -e <name>.age
{ inputs, ... }:
{
  flake.nixosModules.agenix = inputs.agenix.nixosModules.default;

  perSystem =
    { system, ... }:
    {
      packages.agenix = inputs.agenix.packages.${system}.default;
    };
}
