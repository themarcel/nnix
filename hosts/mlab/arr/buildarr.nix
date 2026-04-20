# Buildarr - https://buildarr.github.io/
# A solution to automating deployment and configuration of your *Arr stack.
{
  config,
  _pkgs,
  _lib,
  ...
}: {
  sops.templates."buildarr.yml" = {
    content = ''
      buildarr:
        watch_config: true
        update_days:
          - "monday"
          - "tuesday"
          - "wednesday"
          - "thursday"
          - "friday"
          - "saturday"
          - "sunday"
        update_times:
          - "03:00"

      sonarr:
        hostname: "127.0.0.1"
        port: 8989
        protocol: "http"
        api_key: "${config.sops.placeholder.sonarr_api}"
        settings:
          download_clients:
            qbittorrent:
              - name: "qBittorrent"
                enable: true
                host: "127.0.0.1"
                port: 8081
                username: "${config.sops.placeholder.web_user}"
                password: "${config.sops.placeholder.web_pass}"
                category: "tv"
            sabnzbd:
              - name: "SABnzbd"
                enable: true
                hostname: 127.0.0.1
                port: 8080
                api_key: "${config.sops.placeholder.sabnzbd_api}"
                category: "tv"

      radarr:
        hostname: "127.0.0.1"
        port: 7878
        protocol: "http"
        api_key: "${config.sops.placeholder.radarr_api}"
        settings:
          download_clients:
            definitions:
              qBittorrent:
                type: "qbittorrent"
                enable: true
                hostname: "127.0.0.1"
                port: 8081
                username: "${config.sops.placeholder.web_user}"
                password: "${config.sops.placeholder.web_pass}"
                category: "movies"
              SABnzbd:
                type: "sabnzbd"
                enable: true
                hostname: 127.0.0.1
                port: 8080
                api_key: "${config.sops.placeholder.sabnzbd_api}"
                category: "movies"

      prowlarr:
        hostname: "127.0.0.1"
        port: 9696
        protocol: "http"
        api_key: "${config.sops.placeholder.prowlarr_api}"
        settings:
          apps:
            applications:
              definitions:
                Lidarr:
                  type: "lidarr"
                  prowlarr_url: "http://127.0.0.1:9696"
                  base_url: "http://127.0.0.1:8686"
                  api_key: "${config.sops.placeholder.lidarr_api}"
                  sync_level: "add-and-remove-only"
                  sync_categories:
                    - "Audio/MP3"
                    - "Audio/Audiobook"
                    - "Audio/Lossless"
                    - "Audio/Other"
                    - "Audio/Foreign"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/buildarr 0775 1000 986 -"
  ];

  virtualisation.oci-containers.containers.buildarr = {
    image = "callum027/buildarr:latest";
    volumes = [
      "/var/lib/buildarr:/config"
    ];
    environment = {
      TZ = config.time.timeZone;
      PUID = "1000";
      PGID = "986";
    };
    extraOptions = [
      "--network=host"
      "--init"
    ];
  };

  systemd.services."podman-buildarr" = {
    preStart = ''
      cp -f ${config.sops.templates."buildarr.yml".path} /var/lib/buildarr/buildarr.yml
      chown 1000:986 /var/lib/buildarr/buildarr.yml
      chmod 640 /var/lib/buildarr/buildarr.yml
    '';
    restartTriggers = [
      config.sops.templates."buildarr.yml".content
    ];
  };
}
