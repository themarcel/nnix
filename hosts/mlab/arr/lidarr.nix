{
  _config,
  _pkgs,
  lib,
  _services,
  ...
}: {
  sops.secrets."lidarr_api" = {
    owner = "lidarr";
  };

  services.lidarr = {
    enable = true;
    openFirewall = true;
  };
  users.users.lidarr = {
    extraGroups = ["media"];
  };
  systemd.services.
    lidarr.serviceConfig = {
    ReadWritePaths = ["/var/lib/media"];
    UMask = lib.mkForce "0002";
  };
}
