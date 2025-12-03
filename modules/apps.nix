{
  pkgs,
  lib,
  config,
  hostname,
  ...
}: let
  hostProfiles = {
    # Personal hosts
    salusa = "personal";
    caladan = "personal";
    landerb-mac2 = "work";
  };

  # Get the profile for current host, default to "personal"
  currentProfile = hostProfiles.${hostname} or "personal";

  # Helper to merge module lists
  mkModules = profiles:
    [./apps-common.nix]
    ++ lib.optionals (builtins.elem "personal" profiles) [./apps-personal.nix]
    ++ lib.optionals (builtins.elem "work" profiles) [./apps-work.nix];
in {
  ##########################################################################
  #
  #  Host-specific application configuration
  #
  #  This module orchestrates loading of common and host-specific apps.
  #  - apps-common.nix: Programs installed on all hosts
  #  - apps-personal.nix: Additional programs for personal machines
  #  - apps-work.nix: Additional programs for work machines
  #
  ##########################################################################

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Import the appropriate modules based on host profile
  imports = mkModules [currentProfile];
}
