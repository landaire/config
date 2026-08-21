# Cherry-pick fast-moving packages from nixpkgs master while the rest of the
# system stays on the cached nixpkgs-unstable channel. yt-dlp breaks at runtime
# whenever YouTube changes and needs updating faster than unstable advances.
#
# Add any package you routinely have to wait on to `fromMaster`. Keep the list
# short: each entry loses binary-cache coverage and builds from source.
inputs:
let
  fromMaster = [
    "yt-dlp"
  ];
in
final: prev:
let
  # Inherit prev's config so unfree/overlay settings carry over to the master
  # instance too.
  master = import inputs.nixpkgs-master {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
  };
in
prev.lib.getAttrs fromMaster master
