{
  _config,
  pkgs,
  lib,
  services,
  ...
}: {
  services.stalwart = {
    enable = true;
    stateVersion = "26.05";

    settings = {
      server.hostname = lib.removePrefix "https://" services.stalwart.href;

      server.listener = {
        jmap = {
          bind = ["127.0.0.1:${toString services.stalwart.port}"];
          protocol = "http";
        };
        management = {
          bind = ["127.0.0.1:8081"];
          protocol = "http";
        };
      };

      jmap.url = "https://jmap.yourdomain.com";

      storage = {
        data = "postgres";
        blob = "postgres";
        directory = "postgres";
      };

      store.postgres = {
        type = "postgres";
        url = "postgresql://stalwart-mail@%2Frun%2Fpostgresql/stalwart";
      };

      directory.postgres = {
        type = "sql";
        store = "postgres";
      };
    };
  };

  environment.systemPackages = [pkgs.stalwart-mail];
}
