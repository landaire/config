# Secrets are age files under secrets/, encrypted to the keys listed in
# secrets/secrets.nix. Hosts decrypt them with their SSH host key: NixOS during
# activation, nix-darwin from a launchd daemon. Edit one with:
#   cd secrets && nix run 'path:..#agenix' -- -e <name>.age
{ inputs, ... }:
{
  flake.nixosModules.agenix = inputs.agenix.nixosModules.default;
  flake.darwinModules.agenix = inputs.agenix.darwinModules.default;

  perSystem =
    { system, ... }:
    {
      packages.agenix = inputs.agenix.packages.${system}.default;
    };
}
