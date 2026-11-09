{
  inputs = {
    # The deployment uses the enclosing Git source so this relative input keeps
    # the shared host configuration while maintaining a separate lock graph.
    base.url = "path:../..";

    # Private input kept out of the shared workstation and server lock graph.
    # Do not follow the base nixpkgs pin. Poseidon's pin selects the CUDA
    # llama-cpp build served by cache.nixos-cuda.org.
    poseidon.url = "github:landaire/poseidon";
  };

  outputs =
    { base, poseidon, ... }:
    {
      nixosConfigurations.junction = base.nixosConfigurations.junction.extendModules {
        modules = [
          poseidon.nixosModules.default
          ./poseidon.nix
        ];
      };
    };
}
