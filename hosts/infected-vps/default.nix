{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  services.logrotate.checkConfig = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  networking.hostName = "marcel-cool-vps";

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
  ];

  system.stateVersion = "24.11";
}
