args: {
  shell = import ./shell.nix args;
  generators = import ./generators.nix args;
  systems = import ./systems.nix args;
}
