{
  config,
  pkgs,
  lib,
  services,
  ...
}: {
  sops.secrets."stalwart_admin_pass" = {
    owner = "stalwart";
  };
  users.users.stalwart.extraGroups = ["postgres"];
  services.stalwart = {
    enable = true;
    stateVersion = "26.05";

    settings = {
      server.hostname = lib.removePrefix "https://" services.stalwart.href;
      server.trusted-proxies = ["127.0.0.1" "::1"];

      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:${config.sops.secrets.stalwart_admin_pass.path}}%";
      };

      server.listener = {
        jmap = {
          bind = ["127.0.0.1:${toString services.stalwart.port}"];
          protocol = "http";
        };
        management = {
          bind = ["127.0.0.1:8087"];
          protocol = "http";
          url = services.stalwartadmin.href;
        };
      };

      jmap = {
        url = "${services.stalwart.href}/jmap";
        download-url = "${services.stalwart.href}/jmap/download/{accountId}/{blobId}/{name}?accept={type}";
        upload-url = "${services.stalwart.href}/jmap/upload/{accountId}/";
        event-source-url = "${services.stalwart.href}/jmap/eventsource/?types={types}&closeafter={closeafter}&ping={ping}";
      };

      storage = {
        data = "postgres";
        blob = "postgres";
        directory = "postgres";
        lookup = "postgres";
        fts = "postgres";
      };

      store.postgres = {
        type = "postgresql";
        host = "/run/postgresql";
        port = 5432;
        database = "stalwart";
        user = "stalwart";
        password = "dummy_password";
        tls.enable = false;
      };

      tracer.stdout = {
        type = "stdout";
        level = "info";
        enable = true;
      };

      directory.postgres = {
        type = "internal";
        store = "postgres";
      };

      lookup.postgres = {
        type = "sql";
        store = "postgres";
      };

      fts.postgres = {
        type = "sql";
        store = "postgres";
      };
    };
  };

  systemd.services.stalwart.serviceConfig = {
    BindReadOnlyPaths = ["/run/postgresql"];
    RestrictAddressFamilies = lib.mkAfter ["AF_UNIX"];
  };
  environment.systemPackages = [pkgs.stalwart-mail];
}
