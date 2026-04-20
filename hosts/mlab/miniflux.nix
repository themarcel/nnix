{
  config,
  _lib,
  services,
  ...
}: {
  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = "127.0.0.1:${toString services.miniflux.port}";
      BASE_URL = services.miniflux.href;
    };
    adminCredentialsFile = config.sops.secrets.miniflux_admin_credentials.path;
  };

  sops.secrets."miniflux_admin_credentials" = {};
  sops.secrets."miniflux_api" = {};
}
