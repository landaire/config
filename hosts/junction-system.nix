{ config, ... }:

{
  imports = [ ./junction-hardware.nix ];

  allowedUnfreePackageNames = [
    "nvidia-kernel-modules"
    "nvidia-x11"
  ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = false;
    open = false;
    powerManagement.enable = false;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
