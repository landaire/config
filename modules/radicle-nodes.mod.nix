{
  flake.darwinModules.radicle-nodes =
    {
      hostName,
      lib,
      username,
      ...
    }:
    let
      nodesFile = ../secrets/radicle-nodes.json.age;
      enabledHosts = [
        "caladan"
        "rossak"
      ];
      configDirectory = "/Users/${username}/.config/radicle";
    in
    lib.mkIf (builtins.elem hostName enabledHosts && builtins.pathExists nodesFile) {
      age.secrets.radicle-nodes = {
        file = nodesFile;
        path = "${configDirectory}/nodes.json";
        symlink = false;
        owner = username;
        group = "staff";
        mode = "0600";
      };

      system.activationScripts.extraActivation.text = lib.mkAfter ''
        install -d -m 0700 -o ${username} -g staff ${configDirectory}
      '';
    };
}
