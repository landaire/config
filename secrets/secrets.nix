# Recipients of each secret, read by the agenix CLI. After changing a
# recipient list, run `agenix --rekey` from this directory.
let
  keys = import ../keys.nix;
in
{
  "radicle-github-token.age".publicKeys = keys.users ++ [ keys.hosts.junction ];
}
