{
  self,
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  nix = {
    settings = {
      # Necessary for using flakes on this system.
      experimental-features = "nix-command flakes";
    };
    # do garbage collection weekly to keep disk usage low
    gc = {
      automatic = lib.mkDefault true;
      options = lib.mkDefault "--delete-older-than 7d";
    };
  };

  # Global sops configuration
  #sops.age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
  #sops.age.generateKey = false;
  #sops.age.sshKeyPaths = [];  # Don't look for SSH keys

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
