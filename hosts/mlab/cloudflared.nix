{
  config,
  _pkgs,
  lib,
  services,
  ...
}: {
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};
  sops.secrets."cloudflared_tunnel_json" = {
    owner = "cloudflared";
    group = "cloudflared";
  };
  sops.templates."tunnel.json" = {
    content = config.sops.placeholder.cloudflared_tunnel_json;
    owner = "cloudflared";
    group = "cloudflared";
  };
  services.cloudflared = {
    enable = true;
    tunnels = {
      "fd3b9e36-1dac-426c-9f99-31128df4f799" = {
        credentialsFile = config.sops.templates."tunnel.json".path;
        default = "http://127.0.0.1:80";
        # ingress = lib.mapAttrs (name: service: "http://127.0.0.1:80") services;
        ingress =
          (lib.mapAttrs (name: service: "http://127.0.0.1:80") services)
          // {
            "marcel.cool" = "http://127.0.0.1:80";
          };
      };
    };
  };
}
