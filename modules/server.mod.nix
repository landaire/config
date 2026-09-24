{
  # bcachefs is out of tree as of 6.18. supportedFilesystems pulls the module
  # matching boot.kernelPackages plus bcachefs-tools and initrd support, so a
  # kernel that outpaces the module fails the rebuild rather than the boot.
  flake.nixosModules.boot =
    { pkgs, ... }:
    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      boot.kernelPackages = pkgs.linuxPackages_latest;
      boot.supportedFilesystems.bcachefs = true;
    };

  flake.nixosModules.openssh =
    { username, ... }:
    let
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB6CmOIY8QOpHzEN3otjDVxtabXC6evXnSBtdVHY9e95 landerbrandt@gmail.com"
      ];
    in
    {
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };

      users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
      users.users.${username}.openssh.authorizedKeys.keys = authorizedKeys;
    };

  # Publish <hostName>.local so clients reach this box by name instead of a
  # DHCP address. macOS and Windows 10+ resolve mDNS natively; nssmdns4 lets
  # this host resolve other .local names too.
  flake.nixosModules.mdns = {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
      };
    };
  };

  # Headless defaults. No swap partition was made; zram covers spikes.
  flake.nixosModules.server = {
    networking.useDHCP = true;

    # Opens the 60000-61000/udp range in the firewall alongside the package.
    programs.mosh.enable = true;

    time.timeZone = "America/Los_Angeles";

    services.fstrim.enable = true;
    zramSwap.enable = true;
  };
}
