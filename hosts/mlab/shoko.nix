{
  _config,
  _pkgs,
  lib,
  ...
}: {
  services.shoko = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/media/anime 2775 root media -"
    "d /var/lib/media/downloads/anime 2775 root media -"
  ];

  # inject 'media' group access directly into the systemd service
  systemd.services.shoko.serviceConfig = {
    SupplementaryGroups = ["media"];
    ReadWritePaths = ["/var/lib/media"];
    UMask = lib.mkForce "0002";
  };
}
