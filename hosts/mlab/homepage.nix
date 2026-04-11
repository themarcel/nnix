{
  config,
  ports,
  ...
}: {
  sops.templates."homepage.env" = {
    content = ''
      HOMEPAGE_ALLOWED_HOSTS="home.marcel.cool,127.0.0.1,localhost"
      HOMEPAGE_VAR_WEB_USER='${config.sops.placeholder.web_user}'
      HOMEPAGE_VAR_WEB_PASS='${config.sops.placeholder.web_pass}'
      HOMEPAGE_VAR_SONARR_API='${config.sops.placeholder.sonarr_api}'
      HOMEPAGE_VAR_RADARR_API='${config.sops.placeholder.radarr_api}'
      HOMEPAGE_VAR_LIDARR_API='${config.sops.placeholder.lidarr_api}'
      HOMEPAGE_VAR_PROWLARR_API='${config.sops.placeholder.prowlarr_api}'
      HOMEPAGE_VAR_SABNZBD_API='${config.sops.placeholder.sabnzbd_api}'
      HOMEPAGE_VAR_JELLYFIN_API='${config.sops.placeholder.jellyfin_api}'
      HOMEPAGE_VAR_NAVIDROME_TOKEN='${config.sops.placeholder.navidrome_token}'
      HOMEPAGE_VAR_NAVIDROME_SALT='${config.sops.placeholder.navidrome_salt}'
      HOMEPAGE_VAR_BAZARR_API='${config.sops.placeholder.bazarr_api}'
      HOMEPAGE_VAR_IMMICH_API='${config.sops.placeholder.immich_api}'
      HOMEPAGE_VAR_SEERR_API='${config.sops.placeholder.seerr_api}'
    '';
  };
  services.homepage-dashboard = {
    enable = true;
    listenPort = ports.home;
    environmentFiles = [config.sops.templates."homepage.env".path];

    settings = {
      title = "Mlab Dashboard";
      color = "zinc";
      theme = "dark";
      useEqualHeights = true;
      layout = {
        "Media" = {
          style = "row";
          columns = 4;
        };
        "Automation" = {
          style = "row";
          columns = 4;
        };
        "Downloads" = {
          style = "row";
          columns = 3;
        };
        "Infrastructure" = {
          style = "row";
          columns = 3;
        };
      };
    };

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
    ];

    services = [
      {
        "Media" = [
          {
            Jellyfin = {
              icon = "jellyfin";
              href = "https://jellyfin.marcel.cool";
              description = "Movies & TV";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:${toString ports.jellyfin}";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API}}";
              };
            };
          }
          {
            Navidrome = {
              icon = "navidrome";
              href = "https://music.marcel.cool";
              description = "Music Streamer";
              widget = {
                type = "navidrome";
                url = "http://127.0.0.1:${toString ports.navidrome}";
                user = "{{HOMEPAGE_VAR_WEB_USER}}";
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
              };
            };
          }
          {
            Immich = {
              icon = "immich";
              href = "https://img.marcel.cool";
              description = "Photos";
              widget = {
                type = "immich";
                url = "http://127.0.0.1:${toString ports.immich}";
                key = "{{HOMEPAGE_VAR_IMMICH_API}}";
                version = 2;
              };
            };
          }
          {
            Audiobookshelf = {
              icon = "audiobookshelf";
              href = "https://audiobooks.marcel.cool";
              description = "Audiobooks";
            };
          }
          {
            Calibre = {
              icon = "book";
              href = "https://calibre.marcel.cool";
              description = "E-Book Library";
            };
          }
        ];
      }
      {
        "Automation" = [
          {
            Seerr = {
              icon = "seerr";
              href = "https://seerr.marcel.cool";
              description = "Requests";
              widget = {
                type = "seerr";
                url = "http://127.0.0.1:${toString ports.seerr}";
                key = "{{HOMEPAGE_VAR_SEERR_API}}";
              };
            };
          }
          {
            Sonarr = {
              icon = "sonarr";
              href = "https://sonarr.marcel.cool";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:${toString ports.sonarr}";
                key = "{{HOMEPAGE_VAR_SONARR_API}}";
              };
            };
          }
          {
            Radarr = {
              icon = "radarr";
              href = "https://radarr.marcel.cool";
              widget = {
                type = "radarr";
                url = "http://127.0.0.1:${toString ports.radarr}";
                key = "{{HOMEPAGE_VAR_RADARR_API}}";
              };
            };
          }
          {
            Lidarr = {
              icon = "lidarr";
              href = "https://lidarr.marcel.cool";
              widget = {
                type = "lidarr";
                url = "http://127.0.0.1:${toString ports.lidarr}";
                key = "{{HOMEPAGE_VAR_LIDARR_API}}";
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr";
              href = "https://bazarr.marcel.cool";
              widget = {
                type = "bazarr";
                url = "http://127.0.0.1:${toString ports.bazarr}";
                key = "{{HOMEPAGE_VAR_BAZARR_API}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr";
              href = "https://prowlarr.marcel.cool";
              widget = {
                type = "prowlarr";
                url = "http://127.0.0.1:${toString ports.prowlarr}";
                key = "{{HOMEPAGE_VAR_PROWLARR_API}}";
              };
            };
          }
          {
            Chaptarr = {
              icon = "readarr";
              href = "https://chaptarr.marcel.cool";
              description = "Audiobook Automation";
            };
          }
          {
            Soulbeet = {
              icon = "music";
              href = "https://soulbeet.marcel.cool";
              description = "Music Tagging";
            };
          }
        ];
      }
      {
        "Downloads" = [
          {
            qBittorrent = {
              icon = "qbittorrent";
              href = "https://qbit.marcel.cool";
              widget = {
                type = "qbittorrent";
                url = "http://127.0.0.1:${toString ports.qbit}";
                username = "{{HOMEPAGE_VAR_WEB_USER}}";
                password = "{{HOMEPAGE_VAR_WEB_PASS}}";
              };
            };
          }
          {
            SABnzbd = {
              icon = "sabnzbd";
              href = "https://sabnzbd.marcel.cool";
              widget = {
                type = "sabnzbd";
                url = "http://127.0.0.1:${toString ports.sabnzbd}";
                key = "{{HOMEPAGE_VAR_SABNZBD_API}}";
              };
            };
          }
          {
            Slskd = {
              icon = "soulseek";
              href = "https://slskd.marcel.cool";
              description = "P2P Music";
            };
          }
        ];
      }
      {
        "Infrastructure" = [
          {
            "Open WebUI" = {
              icon = "ollama";
              href = "https://ai.marcel.cool";
              description = "Local AI";
            };
          }
          {
            Seafile = {
              icon = "seafile";
              href = "https://seafile.marcel.cool";
              description = "File Sync";
            };
          }
          {
            Status = {
              icon = "uptime-kuma";
              href = "https://status.marcel.cool";
              description = "Uptime Kuma";
            };
          }
          {
            Grafana = {
              icon = "grafana";
              href = "https://grafana.marcel.cool";
              description = "Server Metrics";
            };
          }
        ];
      }
    ];
  };
}
