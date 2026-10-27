# Recipients of each secret, read by the agenix CLI. After changing a
# recipient list, run `agenix --rekey` from this directory.
let
  keys = import ../keys.nix;

  # Berkeley Mono is licensed per person. Hosts listed here install it; see
  # modules/fonts.mod.nix.
  fontRecipients = keys.users ++ [keys.hosts.rossak];
  font = name: {
    name = "fonts/${name}.age";
    value.publicKeys = fontRecipients;
  };
in
  {
    "radicle-github-token.age".publicKeys = keys.users ++ [keys.hosts.junction];
    "spotify-playlist-config.age".publicKeys = keys.users ++ [keys.hosts.junction];
    "spotify-playlist-session.age".publicKeys = keys.users ++ [keys.hosts.junction];
  }
  // builtins.listToAttrs (
    map font [
      "BerkeleyMono-Regular.otf"
      "BerkeleyMono-Bold.otf"
      "BerkeleyMono-Oblique.otf"
      "BerkeleyMono-Bold-Oblique.otf"
    ]
  )
