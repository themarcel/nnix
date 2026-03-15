{
  config,
  pkgs,
  lib,
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

  services.caddy = {
    enable = true;
    virtualHosts."ai.marcel.cool" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 3000 80 443 ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  services.logrotate.checkConfig = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  networking.hostName = "marcel-cool-vps";

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];

  system.stateVersion = "24.11";
}
