{ lib, ... }:
lib.systems.nixosSystem "junction" {
  username = "lander";
  useremail = "hello@landaire.net";
  profile = "personal";
  hardware = ./junction-hardware.nix;
}
