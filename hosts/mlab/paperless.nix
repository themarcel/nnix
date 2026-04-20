{
  config,
  _lib,
  services,
  ...
}: {
  services.paperless = {
    enable = true;
    port = services.paperless.port;
    address = "127.0.0.1";

    passwordFile = config.sops.secrets.paperless_admin_password.path;

    settings = {
      PAPERLESS_URL = "https://paperless.marcel.cool";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBNAME = "paperless";
      PAPERLESS_DBUSER = "paperless";
      # (add "spa" for spanish, "cat" for catalan, etc., if needed)
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_TIME_ZONE = config.time.timeZone;
    };
  };

  sops.secrets."paperless_api" = {};
  sops.secrets."paperless_admin_password" = {
    owner = "paperless";
  };
}
