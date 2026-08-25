# reindeer's rlimit test asserts it can raise RLIMIT_NOFILE to 1048576, but the
# nix build sandbox caps it lower, so the test panics and fails the build. Skip
# that one test; compilation and the rest of the suite are fine.
final: prev: {
  reindeer = prev.reindeer.overrideAttrs (old: {
    checkFlags = (old.checkFlags or [ ]) ++ [
      "--skip=rlimit::tests::raise_does_not_lower_limit"
    ];
  });
}
