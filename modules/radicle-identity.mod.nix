{
  flake.darwinModules.radicle-identity =
    {
      hostName,
      lib,
      username,
      ...
    }:
    let
      privateKeyFile = ../secrets/radicle-identities + "/${hostName}.age";
      publicKeyFile = ../secrets/radicle-identities + "/${hostName}.pub.age";
      keyDirectory = "/Users/${username}/.radicle/keys";
    in
    lib.mkIf (builtins.pathExists privateKeyFile && builtins.pathExists publicKeyFile) {
      age.secrets.radicle-identity-private = {
        file = privateKeyFile;
        path = "${keyDirectory}/radicle";
        symlink = false;
        owner = username;
        group = "staff";
        mode = "0600";
      };
      age.secrets.radicle-identity-public = {
        file = publicKeyFile;
        path = "${keyDirectory}/radicle.pub";
        symlink = false;
        owner = username;
        group = "staff";
        mode = "0644";
      };

      system.activationScripts.extraActivation.text = lib.mkAfter ''
        install -d -m 0755 -o ${username} -g staff /Users/${username}/.radicle
        install -d -m 0700 -o ${username} -g staff ${keyDirectory}
      '';
    };
}
