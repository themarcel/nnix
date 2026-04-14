{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  services = {
    audiobooks = {
      port = 8000;
      href = "https://audiobooks.marcel.cool";
    };
    authelia = {
      port = 9091;
      href = "https://auth.marcel.cool";
    };
    bazarr = {
      port = 6767;
      href = "https://bazarr.marcel.cool";
    };
    calibre = {
      port = 8083;
      href = "https://calibre.marcel.cool";
    };
    chaptarr = {
      port = 8789;
      href = "https://chaptarr.marcel.cool";
    };
    grafana = {
      port = 3005;
      href = "https://grafana.marcel.cool";
    };
    home = {
      port = 8082;
      href = "https://home.marcel.cool";
    };
    immich = {
      port = 2283;
      href = "https://img.marcel.cool";
    };
    jellyfin = {
      port = 8096;
      href = "https://jellyfin.marcel.cool";
    };
    lidarr = {
      port = 8686;
      href = "https://lidarr.marcel.cool";
    };
    navidrome = {
      port = 4533;
      href = "https://music.marcel.cool";
    };
    openwebui = {
      port = 3000;
      href = "https://ai.marcel.cool";
    };
    prowlarr = {
      port = 9696;
      href = "https://prowlarr.marcel.cool";
    };
    qbit = {
      port = 8081;
      href = "https://qbit.marcel.cool";
    };
    radarr = {
      port = 7878;
      href = "https://radarr.marcel.cool";
    };
    sabnzbd = {
      port = 8080;
      href = "https://sabnzbd.marcel.cool";
    };
    seafile = {
      port = 8008;
      href = "https://seafile.marcel.cool";
    };
    seerr = {
      port = 5055;
      href = "https://seerr.marcel.cool";
    };
    shoko = {
      port = 8111;
      href = "https://shoko.marcel.cool";
    };
    slskd = {
      port = 5030;
      href = "https://slskd.marcel.cool";
    };
    sonarr = {
      port = 8989;
      href = "https://sonarr.marcel.cool";
    };
    soulbeet = {
      port = 9765;
      href = "https://soulbeet.marcel.cool";
    };
    status = {
      port = 3001;
      href = "https://status.marcel.cool";
    };
    prometheus = {
      port = 9090;
      href = "http://127.0.0.1:9090";
    };
  };

  mkProxyHost = name: service: {
    serverName = lib.removePrefix "https://" service.href;
    listen = [
      {
        addr = "0.0.0.0";
        port = 80;
      }
    ];
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString service.port}";
      proxyWebsockets = true;
      extraConfig = ''
        # Tell the app what the original URL and IP were
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;

        proxy_connect_timeout 3s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        error_page 502 503 504 = @maintenance;
      '';
    };
    extraConfig = ''
      location @maintenance {
        return 307 https://maintenance.marcel.cool?from=${lib.removePrefix "https://" service.href};
      }
    '';
  };

  serviceVirtualHosts = lib.mapAttrs mkProxyHost services;
in {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    ./arr
    ./graphana.nix
    ./homepage.nix
    ./seafile.nix
    ./shoko.nix
  ];
  _module.args.services = services;

  time.timeZone = "Europe/Madrid";

  programs.mosh.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/mlab.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "app_pass" = {};
      "app_user" = {};
      "authelia_jwt_secret" = {owner = "authelia-main";};
      "authelia_session_secret" = {owner = "authelia-main";};
      "authelia_storage_encryption_key" = {owner = "authelia-main";};
      "authelia_oidc_hmac_secret" = {owner = "authelia-main";};
      "authelia_oidc_issuer_key" = {owner = "authelia-main";};
      "authelia_tailscale_client_secret" = {owner = "authelia-main";};
      "authelia_admin_password" = {owner = "authelia-main";};
      "bazarr_api" = {};
      "cloudflare_ddclient_token" = {
        owner = "ddclient";
        group = "ddclient";
      };
      "cloudflared_tunnel_json" = {
        owner = "cloudflared";
        group = "cloudflared";
      };
      "immich_api" = {};
      "jellyfin_api" = {};
      "josep_password" = {
        neededForUsers = true;
      };
      "lidarr_api" = {};
      "navidrome_salt" = {};
      "navidrome_token" = {};
      "prowlarr_api" = {};
      "qbit_password_hash" = {};
      "qbit_password_salt" = {};
      "radarr_api" = {};
      "sabnzbd_api" = {};
      "seerr_api" = {};
      "slsk_pass" = {};
      "slsk_user" = {};
      "slskd_api_key" = {};
      "sonarr_api" = {};
      "soulbeet_secret_key" = {};
      "web_pass" = {};
      "web_user" = {};
      "grafana_secret_key" = {
        owner = "grafana";
      };
    };

    templates."authelia-env" = {
      content = ''
        AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET=${config.sops.placeholder.authelia_jwt_secret}
        AUTHELIA_SESSION_SECRET=${config.sops.placeholder.authelia_session_secret}
        AUTHELIA_STORAGE_ENCRYPTION_KEY=${config.sops.placeholder.authelia_storage_encryption_key}
        AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET=${config.sops.placeholder.authelia_oidc_hmac_secret}
      '';
      owner = "authelia-main";
    };

    templates."authelia-users" = {
      content = ''
        users:
          authelia:
            displayname: "Authelia Admin"
            password: "${config.sops.placeholder.authelia_admin_password}"
            email: "authelia@auth.marcel.cool"
            groups:
              - admins
      '';
      owner = "authelia-main";
    };

    templates."tunnel.json" = {
      content = config.sops.placeholder.cloudflared_tunnel_json;
      owner = "cloudflared";
      group = "cloudflared";
    };

    templates."qBittorrent.conf" = {
      content = ''
        [Preferences]
        WebUI\Username=${config.sops.placeholder.web_user}
        WebUI\Port=${toString services.qbit.port}
        WebUI\LocalHostAuthentication=false
        WebUI\AuthSubnetWhitelist=127.0.0.1/32,192.168.1.0/24
        Connection\AddressFamily=Both
        Connection\Interface=enp87s0
        Downloads\SavePath=/var/lib/media/downloads/
        Session\DefaultSavePath=/var/lib/media/downloads/
        Session\TempPath=/var/lib/media/downloads/incomplete/
      '';
      owner = "qbittorrent";
      group = "media";
    };

    templates."slskd-mlab.env" = {
      content = ''
        APP_DIR=/var/lib/slskd

        SLSKD_SLSK_USERNAME='${config.sops.placeholder.slsk_user}'
        SLSKD_SLSK_PASSWORD='${config.sops.placeholder.slsk_pass}'

        SLSKD_USERNAME='${config.sops.placeholder.web_user}'
        SLSKD_PASSWORD='${config.sops.placeholder.web_pass}'

        SLSKD_WEB_USERNAME=${config.sops.placeholder.web_user}
        SLSKD_WEB_PASSWORD=${config.sops.placeholder.web_pass}
      '';
      owner = "slskd";
    };
  };

  services.uptime-kuma.enable = true;

  services.nginx = {
    enable = true;
    clientMaxBodySize = "0";

    virtualHosts =
      serviceVirtualHosts
      // {
        "auth.marcel.cool" = let
          base = mkProxyHost "authelia" services.authelia;
        in
          base
          // {
            locations =
              base.locations
              // {
                "/.well-known/webfinger".extraConfig = ''
                  add_header Content-Type application/jrd+json;
                  return 200 '{"subject":"acct:authelia@auth.marcel.cool","links":[{"rel":"http://openid.net/specs/connect/1.0/issuer","href":"https://auth.marcel.cool"}]}';
                '';
              };
          };

        "_" = {
          default = true;
          listen = [
            {
              addr = "0.0.0.0";
              port = 80;
            }
          ];
          locations."/" = {
            return = "307 https://maintenance.marcel.cool";
          };
        };
      };
  };

  services.audiobookshelf = {
    enable = true;
    port = services.audiobooks.port;
    openFirewall = true;
  };
  users.users.audiobookshelf = {
    extraGroups = ["media"];
  };

  virtualisation.oci-containers.containers.calibre-web-automated = {
    image = "crocodilestick/calibre-web-automated:latest";
    volumes = [
      "/var/lib/calibre-web-automated/config:/config"
      "/var/lib/media/books:/calibre-library"
      "/var/lib/media/books/import:/cwa-book-ingest"
    ];
    environment = {
      PUID = "951";
      PGID = "986";
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
    };
    extraOptions = [
      "--network=host"
      "--no-healthcheck"
    ];
  };
  users.users.calibre = {
    isSystemUser = true;
    group = "calibre";
    extraGroups = ["media"];
    uid = 951;
  };
  users.groups.calibre = {
    gid = 951;
  };
  users.groups.media.gid = 986;

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    # Soulbeet and slskd
    "d /var/lib/soulbeet 0755 root root -"
    "d /var/lib/slskd 0755 slskd slskd -"
    "d /var/lib/slskd/music 0755 slskd slskd -"
    "d /var/lib/slskd/music/downloads 0755 slskd slskd -"
    "d /var/lib/slskd/music/incompleted 0755 slskd slskd -"
    "d /etc/slskd 0755 slskd slskd -"

    # Shared Media Stack Base
    "d /var/lib/media 0775 root media -"

    # Set GID 2775 on download and import folders ensures
    # that files created by one app are writable by the whole 'media' group.
    "d /var/lib/media/downloads 2775 root media -"
    "d /var/lib/media/downloads/incomplete 2775 root media -"

    # Media Folders
    "d /var/lib/media/tv 0775 root media -"
    "d /var/lib/media/movies 0775 root media -"
    "d /var/lib/media/music 0775 root media -"
    "d /var/lib/media/audiobooks 2775 root media -"

    # Books & Calibre Stack
    # We give 'calibre' primary ownership, but 'media' group rwx access
    "d /var/lib/media/books 0775 calibre media -"
    "d /var/lib/media/books/import 2775 calibre media -"
    "d /var/lib/calibre-web-automated/config 0775 calibre media -"

    # Service Specific
    "d /var/lib/slskd/music/share 0775 slskd media -"
    "d /var/lib/seerr 0775 1000 media -"
    "d /var/lib/chaptarr 0775 chaptarr media -"

    # SABnzbd
    "d /var/lib/sabnzbd 0775 sabnzbd media -"

    # qbit
    "d /var/lib/qbittorrent 0775 qbittorrent media -"
    "d /var/lib/qbittorrent/.config/qBittorrent 0750 qbittorrent qbittorrent -"
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = services.qbit.port;
  };
  systemd.services.qbittorrent.preStart = ''
    # The directory structure is guaranteed by systemd.tmpfiles.rules
    cp -f ${
      config.sops.templates."qBittorrent.conf".path
    } /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
    # Ensure correct permissions for the copied config
    chmod 600 /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
  '';

  systemd.services.ddclient.after = ["nss-user-lookup.target"];
  systemd.services.slskd.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = "5s";
    StateDirectory = "slskd";
    WorkingDirectory = "/var/lib/slskd";
    UMask = "0022";
  };

  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      # TYPE  DATABASE        USER            ADDRESS                 METHOD
      local   all             all                                     ident
      host    all             all             127.0.0.1/32            scram-sha-256
      host    all             all             ::1/128                 scram-sha-256
    '';
    ensureDatabases = ["navidrome"];
    ensureUsers = [
      {
        name = "navidrome";
        ensureDBOwnership = true;
      }
    ];
    settings = {
      # rule of thumb: 25% of total ram for shared_buffers
      shared_buffers = "8GB";
      effective_cache_size = "24GB";
      maintenance_work_mem = "2GB";
      checkpoint_completion_target = 0.9;
      wal_buffers = "16MB";
      autovacuum = "on";
      log_min_duration_statement = 500;
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # for newer intel igpus
      intel-compute-runtime # OpenCL
      vpl-gpu-rt # Required for QSV on Intel 11th Gen and newer
    ];
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = services.openwebui.port;
  };

  services.ddclient = {
    enable = true;
    interval = "5min";
    protocol = "cloudflare";
    zone = "marcel.cool";
    username = "token";
    passwordFile = config.sops.secrets.cloudflare_ddclient_token.path;
    domains = ["ssh.marcel.cool"];
    usev4 = "webv4, webv4=ifconfig.me";
    usev6 = "webv6, webv6=api6.ipify.org";
    ssl = true;
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  sops.templates."soulbeet.env".content = ''
    SLSKD_URL=http://127.0.0.1:${toString services.slskd.port}
    # SLSKD_API_KEY=${config.sops.placeholder.slskd_api_key}
    NAVIDROME_URL=http://127.0.0.1:${toString services.navidrome.port}
    NAVIDROME_USERNAME=${config.sops.placeholder.web_user}
    NAVIDROME_PASSWORD=${config.sops.placeholder.web_pass}
    SECRET_KEY=${config.sops.placeholder.soulbeet_secret_key}
    DATABASE_URL=sqlite:/data/soulbeet.db
    DOWNLOAD_PATH=/var/lib/slskd/music/downloads
    NAVIDROME_MUSIC_PATH=/music
    SOULBEET_URL=https://soulbeet.marcel.cool
  '';

  environment.etc."soulbeet/beets_config.yaml".text = ''
    directory: /music
    library: /data/soulbeet.db

    plugins: fromfilename

    import:
      move: yes
      write: yes
      quiet_fallback: asis
  '';

  virtualisation.oci-containers.containers.soulbeet = {
    image = "docker.io/docccccc/soulbeet:latest";
    environment = {
      BEETSDIR = "/config";
    };
    volumes = [
      "/var/lib/soulbeet:/data"
      "/var/lib/slskd/music/downloads:/var/lib/slskd/music/downloads"
      "/var/lib/slskd/music/share:/music"
      "/etc/soulbeet/beets_config.yaml:/config/config.yaml"
    ];
    environmentFiles = [
      config.sops.templates."soulbeet.env".path
    ];
    extraOptions = ["--network=host"]; # allows easy access to local slskd/navidrome
  };

  virtualisation.oci-containers.containers.seerr = {
    image = "ghcr.io/seerr-team/seerr:latest";
    volumes = [
      "/var/lib/seerr:/app/config"
    ];
    environment = {
      TZ = config.time.timeZone;
      PORT = toString services.seerr.port;
    };
    extraOptions = [
      "--network=host"
      "--init"
    ];
  };

  virtualisation.oci-containers.containers.chaptarr = {
    image = "robertlordhood/chaptarr:latest";
    volumes = [
      "/var/lib/chaptarr:/config"
      "/var/lib/media/books:/var/lib/media/books"
      "/var/lib/media/audiobooks:/var/lib/media/audiobooks"
      "/var/lib/media/downloads:/var/lib/media/downloads"
      "/var/lib/media/books/import:/var/lib/media/books/import"
    ];
    environment = {
      TZ = config.time.timeZone;
      PUID = "950"; # static chaptarr user UID
      PGID = "986"; # system's 'media' group GID
      UMASK = "002"; # allows CWA to move files
    };
    extraOptions = [
      "--network=host"
      "--init"
    ];
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

  services.lidarr = {
    enable = true;
    openFirewall = true;
  };

  services.slskd = {
    enable = true;
    openFirewall = true;
    domain = null;
    user = "slskd";
    group = "slskd";
    environmentFile = config.sops.templates."slskd-mlab.env".path;
    settings = {
      directories = {
        downloads = "/var/lib/slskd/music/downloads";
        incomplete = "/var/lib/slskd/music/incompleted";
      };
      shares = {
        directories = ["/var/lib/slskd/music/share"];
      };
      soulseek = {
        listen_port = 50300;
      };
      web = {
        port = services.slskd.port;
        address = "0.0.0.0";
        authentication = {
          api_keys = {
            soulbeet = {
              key = "slskdAPIkey9988776655aabbccdd";
              role = "administrator";
            };
          };
        };
      };
      global = {
        upload.slots = 10;
        download.slots = 10;
      };
    };
  };

  services.navidrome = {
    enable = true;
    user = "navidrome";
    group = "navidrome";
    settings = {
      DataFolder = "/var/lib/navidrome";
      Address = "0.0.0.0";
      Port = services.navidrome.port;
      MusicFolder = "/var/lib/slskd/music/share";
      DB = {
        Type = "postgres";
        Host = "/run/postgresql";
        User = "navidrome";
        Database = "navidrome";
      };
    };
  };

  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/var/lib/slskd/music/share"
  ];

  networking = {
    hostName = "mlab";
    defaultGateway = "192.168.1.1";

    interfaces = {
      enp87s0 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = "192.168.1.140";
            prefixLength = 24;
          }
        ];
      };
      enp2s0f0np0 = {
        useDHCP = true;
      };
      enp2s0f1np1 = {
        useDHCP = true;
      };
    };
    dhcpcd = {
      extraConfig = ''
        slaac private
        interface enp87s0
        noipv4
      '';
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    tempAddresses = "enabled";
    firewall = {
      enable = true;
      allowedTCPPorts =
        [
          80 # nginx catch-all
          23951 # Qbitorrent
          50300 # Soulseek
          9117 # Jackett
        ]
        ++ builtins.map (v: v.port) (builtins.attrValues services);
      allowedUDPPorts = [23951];
      allowedUDPPortRanges = [
        {
          from = 60000;
          to = 61000;
        }
      ];
      extraCommands = ''
        # Allow traffic from Podman containers to the host
        iptables -A INPUT -i podman+ -p tcp --dport ${toString services.slskd.port} -j ACCEPT
        iptables -A INPUT -i podman+ -p tcp --dport ${toString services.navidrome.port} -j ACCEPT
      '';
      trustedInterfaces = ["podman0"];
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    tmp.cleanOnBoot = true;
    kernelParams = [
      "i915.enable_guc=3" # Forces GuC/HuC firmware loading for Low-Power encoding
    ];
  };

  services.sabnzbd = {
    enable = true;
    openFirewall = true;
    configFile = null;
    group = "media";
    settings = {
      misc = {
        host_whitelist = "sabnzbd.marcel.cool, mlab, 127.0.0.1";
      };
      server = {
        host = "0.0.0.0";
        port = services.sabnzbd.port;
      };
    };
    allowConfigWrite = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  services.logrotate.checkConfig = false;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  security.pam.services.sshd.unixAuth = lib.mkForce true;
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowAgentForwarding = true;
    };
    extraConfig = ''
      Match User josep
        PasswordAuthentication yes
        KbdInteractiveAuthentication yes
    '';
  };

  environment.systemPackages = with pkgs; [
    erdtree
    git
    vim
    lsof
    tree
    git
    duf
    jq
    ripgrep
    tmux
    neovim
    eza
    zoxide
    fd
    fzf
    bat
    bottom
    starship
    direnv
    sysz
    btop
    ethtool
    librespeed-cli
    libreswan
    (writeShellScriptBin "import-music" ''
      if [ -z "$1" ]; then
        echo "No specific folder provided. Importing EVERYTHING in downloads..."
        sudo podman exec -it soulbeet beet import /var/lib/slskd/music/downloads
      else
        echo "Importing: $1"
        sudo podman exec -i soulbeet beet import -q -s -A "/var/lib/slskd/music/downloads/$1"
      fi
    '')
  ];

  environment.sessionVariables.NVIM_PROFILE = "minimal";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # optimization for 32gb + likely a multi-core cpu
    auto-optimise-store = true;
    cores = 0;
    max-jobs = "auto";
  };

  users = {
    users.dev = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7c4J3kFLiJYHqUh9zkybQu0pjOu8tyofUnsd67se9m mlab server key"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHe+ZUUCwet0+uaGYfr3hE4zNVASmQPWuoGpk5QAbKG4 nix-on-droid@localhost"
      ];
    };
    users.josep = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.josep_password.path;
    };
    users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7c4J3kFLiJYHqUh9zkybQu0pjOu8tyofUnsd67se9m mlab server key"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHe+ZUUCwet0+uaGYfr3hE4zNVASmQPWuoGpk5QAbKG4 nix-on-droid@localhost"
      ];
    };

    users.slskd = {
      isSystemUser = true;
      group = "slskd";
      home = "/var/lib/slskd";
      createHome = true;
    };
    groups.slskd = {};

    users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
    };
    groups.cloudflared = {};

    users.navidrome = {
      isSystemUser = true;
      group = "navidrome";
      extraGroups = ["slskd"];
      home = "/var/lib/navidrome";
      createHome = true;
    };
    groups.navidrome = {};

    users.ddclient = {
      isSystemUser = true;
      group = "ddclient";
    };
    groups.ddclient = {};

    users.jellyfin.extraGroups = [
      "render"
      "video"
      "media"
      "slskd"
    ];
    users.qbittorrent.extraGroups = ["media"];
    groups.media = {};

    users.sonarr = {
      isSystemUser = true;
      group = "sonarr";
      extraGroups = ["media"];
    };
    groups.sonarr = {};

    users.sabnzbd = {
      extraGroups = ["media"];
    };
    users.radarr = {
      extraGroups = ["media"];
    };
    users.lidarr = {
      extraGroups = ["media"];
    };
    users.chaptarr = {
      isSystemUser = true;
      group = "chaptarr";
      extraGroups = ["media"];
      uid = 950;
    };
    groups.chaptarr = {
      gid = 950;
    };
  };

  services.ollama = {
    enable = true;
  };

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = services.immich.port;
  };

  services.bazarr = {
    enable = true;
    group = "media";
    openFirewall = true;
  };
  systemd.services.bazarr.serviceConfig = {
    ReadWritePaths = ["/var/lib/media"];
    UMask = lib.mkForce "0002";
  };

  systemd.services = {
    sonarr.serviceConfig = {
      ReadWritePaths = ["/var/lib/media"];
      UMask = lib.mkForce "0002";
    };
    radarr.serviceConfig = {
      ReadWritePaths = ["/var/lib/media"];
      UMask = lib.mkForce "0002";
    };
    lidarr.serviceConfig = {
      ReadWritePaths = ["/var/lib/media"];
      UMask = lib.mkForce "0002";
    };
    qbittorrent.serviceConfig = {
      ReadWritePaths = ["/var/lib/media"];
      UMask = lib.mkForce "0002";
    };
    sabnzbd.serviceConfig = {
      ReadWritePaths = ["/var/lib/media"];
      UMask = lib.mkForce "0002";
    };
  };

  services.authelia.instances.main = {
    enable = true;
    secrets.manual = true;

    settingsFiles = ["/var/lib/authelia-main/jwks.yml"];

    settings = {
      theme = "dark";
      server.address = "tcp://0.0.0.0:${toString services.authelia.port}";

      session = {
        name = "authelia_session";
        cookies = [
          {
            domain = "marcel.cool";
            authelia_url = "https://auth.marcel.cool";
            default_redirection_url = "https://home.marcel.cool";
          }
        ];
      };

      access_control = {
        default_policy = "one_factor";
      };

      notifier = {
        filesystem = {
          filename = "/var/lib/authelia-main/notification.txt";
        };
      };

      authentication_backend.file.path = config.sops.templates."authelia-users".path;
      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      identity_providers.oidc = {
        clients = [
          {
            client_id = "tailscale";
            client_name = "Tailscale";
            client_secret = "$pbkdf2-sha512$310000$nGGxzhdyKtIYCeeywAwYGA$IhOBt2rIZpnMhGb9.LuetMaU8TMyqZCtIdqepFJbzss34G8OC1ZP.a9m131ccd95ThKqOCb3hzMP8.ypTU0E/w";
            public = false;
            authorization_policy = "one_factor";
            redirect_uris = ["https://login.tailscale.com/a/oauth_response"];
            scopes = ["openid" "profile" "email"];
            userinfo_signed_response_alg = "none";
          }
        ];
      };
    };
  };

  systemd.services.authelia-main = {
    serviceConfig = {
      EnvironmentFile = [config.sops.templates."authelia-env".path];
    };

    preStart = lib.mkBefore ''
      ${pkgs.coreutils}/bin/cat <<EOF > /var/lib/authelia-main/jwks.yml
      identity_providers:
        oidc:
          jwks:
            - key_id: "tailscale-key"
              algorithm: "RS256"
              use: "sig"
              key: |
      EOF
      ${pkgs.gnused}/bin/sed 's/^/          /' ${config.sops.secrets.authelia_oidc_issuer_key.path} >> /var/lib/authelia-main/jwks.yml
      ${pkgs.coreutils}/bin/chmod 600 /var/lib/authelia-main/jwks.yml
    '';
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nvim;
      inherit pkgs;
    };
    users.root = {
      home = {
        stateVersion = "26.05";
        file.".config/tmux".source = "${inputs.dots}/.config/tmux";
        file."scripts".source = "${inputs.dots}/scripts";
        file.".bash_aliases".source = "${inputs.dots}/.bash_aliases";
        file.".config/btop".source = "${inputs.dots}/.config/btop";
      };
    };
    users.dev = {lib, ...}: {
      home = {
        stateVersion = "26.05";
        sessionVariables.NVIM_PROFILE = "minimal";
        packages = with pkgs; [
          atuin
          gnupg
          pass
          carapace
        ];
        file.".bash_aliases".source = "${inputs.dots}/.bash_aliases";
        file."clones/forks/xelabash".source = inputs.xelabash;
        file."scripts".source = "${inputs.dots}/scripts";
        file.".config/tmux".source = "${inputs.dots}/.config/tmux";
        file.".config/atuin".source = "${inputs.dots}/.config/atuin";
        file.".config/carapace".source = "${inputs.dots}/.config/carapace";
        file.".config/git".source = "${inputs.dots}/.config/git";
        file.".config/zoxide".source = "${inputs.dots}/.config/zoxide";
        file.".config/btop".source = "${inputs.dots}/.config/btop";
      };
      programs.bash = {
        enable = true;
        initExtra = ''
          source ${inputs.dots}/.bashrc
        '';
      };
      imports = [inputs.nvim.homeManagerModules.default];
    };
  };

  system.stateVersion = "26.05";
}
