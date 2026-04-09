{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  time.timeZone = "Europe/Madrid";

  programs.mosh.enable = true;

  sops = {
    defaultSopsFile = ../../secrets/mlab.yaml;
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "slsk_user" = {};
      "slsk_pass" = {};
      "web_user" = {};
      "web_pass" = {};
      "app_user" = {};
      "app_pass" = {};
      "josep_password" = {
        neededForUsers = true;
      };
      "cloudflare_ddclient_token" = {
        owner = "ddclient";
        group = "ddclient";
      };
      "slskd_api_key" = {};
      "soulbeet_secret_key" = {};
      "cloudflared_tunnel_json" = {
        owner = "cloudflared";
        group = "cloudflared";
      };
      "sonarr_api" = {};
      "radarr_api" = {};
      "lidarr_api" = {};
      "prowlarr_api" = {};
      "sabnzbd_api" = {};
      "jellyfin_api" = {};
      "navidrome_token" = {};
      "navidrome_salt" = {};
      "qbit_password_hash" = {};
      "qbit_password_salt" = {};
      "bazarr_api" = {};
      "immich_api" = {};
      "seerr_api" = {};
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
        WebUI\Password_PBKDF2="@ByteArray(${config.sops.placeholder.qbit_password_hash})"
        WebUI\Password_Salt="@ByteArray(${config.sops.placeholder.qbit_password_salt})"
        WebUI\Port=8081
        WebUI\AuthSubnetWhitelist=127.0.0.1/32
        Connection\AddressFamily=Both
        Connection\Interface=enp87s0
      '';
      owner = "qbittorrent";
      group = "media";
    };

    templates."slskd-mlab.env" = {
      content = ''
        SLSKD_SLSK_USERNAME='${config.sops.placeholder.slsk_user}'
        SLSKD_SLSK_PASSWORD='${config.sops.placeholder.slsk_pass}'

        SLSKD_USERNAME='${config.sops.placeholder.web_user}'
        SLSKD_PASSWORD='${config.sops.placeholder.web_pass}'

        SLSKD_WEB_USERNAME=${config.sops.placeholder.web_user}
        SLSKD_WEB_PASSWORD=${config.sops.placeholder.web_pass}
      '';
      owner = "slskd";
    };

    templates."homepage.env" = {
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
  };

  services.netdata = {
    enable = true;
    package = pkgs.netdata.override {
      withCloudUi = true;
    };

    config = {
      global = {
        "memory mode" = "dbengine";
        "error log" = "syslog";
      };

      web = {
        "bind to" = "0.0.0.0";
        "allow connections from" = "localhost 127.0.0.1 192.168.1.*";
        "allow dashboard from" = "localhost 127.0.0.1 192.168.1.*";
        "trust proxy" = "yes";
      };

      plugins = {
        "freeipmi" = "no";
      };
    };
  };

  users.users.netdata.extraGroups = ["podman"];

  services.uptime-kuma.enable = true;

  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      default = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = 80;
        }
      ];
      root = ./maintenance;
      locations."/" = {
        tryFiles = "$uri /index.html";
      };
    };
  };

  services.audiobookshelf = {
    enable = true;
    port = 8000;
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
    "d /var/lib/media/downloads/incomplete 0775 root media -"

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
    "d /var/lib/sabnzbd 0750 sabnzbd sabnzbd -"
    "f /var/lib/sabnzbd/sabnzbd.ini 0640 sabnzbd sabnzbd -"

    # netdata fix
    "d /tmp/netdata 0755 netdata netdata -"
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
    webuiPort = 8081;
  };
  systemd.services.qbittorrent.preStart = ''
    mkdir -p /var/lib/qbittorrent/.config/qBittorrent
    cp -f ${config.sops.templates."qBittorrent.conf".path} /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
    # Use the specific user/group from the config to avoid "Invalid Argument"
    chown ${config.services.qbittorrent.user}:${config.services.qbittorrent.group} /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
    chmod 600 /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
  '';

  systemd.services.ddclient.after = ["nss-user-lookup.target"];
  systemd.services.slskd.serviceConfig = {
    ProtectSystem = lib.mkForce false;
    PrivateTmp = lib.mkForce false;
    ProtectHome = lib.mkForce false;
    PrivateDevices = lib.mkForce false;
    ProtectKernelTunables = lib.mkForce false;
    ProtectKernelModules = lib.mkForce false;
    ProtectControlGroups = lib.mkForce false;
    RestrictNamespaces = lib.mkForce false;
    ReadWritePaths = lib.mkForce [
      "/var/lib/slskd"
      "/var/lib/slskd/music"
      "/etc/slskd"
    ];
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
    port = 3000;
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
    # Connection to Slskd
    SLSKD_URL=http://127.0.0.1:5030
    # SLSKD_API_KEY=slskdAPIkey9988776655aabbccdd

    # Connection to Navidrome
    NAVIDROME_URL=http://127.0.0.1:4533
    NAVIDROME_USERNAME=${config.sops.placeholder.web_user}
    NAVIDROME_PASSWORD=${config.sops.placeholder.web_pass}

    # Soulbeet Internal
    SECRET_KEY=${config.sops.placeholder.soulbeet_secret_key}
    DATABASE_URL=sqlite:/data/soulbeet.db
    DOWNLOAD_PATH=/var/lib/slskd/music/downloads
    NAVIDROME_MUSIC_PATH=/music
    SOULBEET_URL=https://soulbeet.marcel.cool
  '';

  environment.etc."soulbeet/beets_config.yaml".text = ''
    directory: /music
    library: /data/soulbeet.db
    import:
      move: yes
  '';

  virtualisation.oci-containers.containers.soulbeet = {
    image = "docker.io/docccccc/soulbeet:latest";
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
      PORT = "5055";
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
      "/var/lib/media/books:/books"
      "/var/lib/media/audiobooks:/var/lib/media/audiobooks"
      "/var/lib/media/downloads:/var/lib/media/downloads"
      "/var/lib/media/books/import:/import"
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
        ingress = {
          "ai.marcel.cool" = "http://127.0.0.1:3000";
          "music.marcel.cool" = "http://127.0.0.1:4533";
          "slskd.marcel.cool" = "http://127.0.0.1:5030";
          "soulbeet.marcel.cool" = "http://127.0.0.1:9765";
          "jellyfin.marcel.cool" = "http://127.0.0.1:8096";
          "qbit.marcel.cool" = "http://127.0.0.1:8081";
          "sonarr.marcel.cool" = "http://127.0.0.1:8989";
          "radarr.marcel.cool" = "http://127.0.0.1:7878";
          "lidarr.marcel.cool" = "http://127.0.0.1:8686";
          "sabnzbd.marcel.cool" = "http://127.0.0.1:8080";
          "prowlarr.marcel.cool" = "http://127.0.0.1:9696";
          "home.marcel.cool" = "http://127.0.0.1:8082";
          "bazarr.marcel.cool" = "http://127.0.0.1:6767";
          "img.marcel.cool" = "http://127.0.0.1:2283";
          "seerr.marcel.cool" = "http://127.0.0.1:5055";
          "chaptarr.marcel.cool" = "http://127.0.0.1:8789";
          "calibre.marcel.cool" = "http://127.0.0.1:8083";
          "audiobooks.marcel.cool" = "http://127.0.0.1:8000";
          "status.marcel.cool" = "http://127.0.0.1:3001";
          "netdata.marcel.cool" = "http://127.0.0.1:19999";
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
        port = 5030;
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
      Port = 4533;
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
      allowedTCPPorts = [
        80 # nginx catch-all
        29888 # Qbitorrent
        3000 # Openwebui
        2283 # Immich
        5030 # slskd
        50300 # Soulseek
        4533 # Navidrome
        9765 # Soulbeet
        8096 # Jellyfin HTTP
        8081 # qBittorrent WebUI
        8080 # SABnzbd
        9117 # Jackett
        8989 # Sonarr
        7878 # Radarr
        9696 # Prowlarr
        6767 # Bazarr
        8082 # Homepage Dashboard
        5055 # Seerr
        8789 # Chaptarr
        8083 # Calibre Web
        8000 # Audiobookshelf
        19999 # Netdata
        3001 # Uptime Kuma
      ];
      allowedUDPPorts = [29888];
      allowedUDPPortRanges = [
        {
          from = 60000;
          to = 61000;
        }
      ];
      extraCommands = ''
        # Allow traffic from Podman containers to the host
        iptables -A INPUT -i podman+ -p tcp --dport 5030 -j ACCEPT
        iptables -A INPUT -i podman+ -p tcp --dport 4533 -j ACCEPT
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
        port = 8080;
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
    git
    vim
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
        sudo podman exec -it soulbeet beet import "/var/lib/slskd/music/downloads/$1"
      fi
    '')
  ];

  # Force 10Gbps and disable auto-negotiation on the X710 interface
  systemd.services.ethtool-force-10g = {
    description = "Force 10Gbps and disable autoneg on enp2s0f0np0";
    after = ["network-pre.target" "sys-subsystem-net-devices-enp2s0f0np0.device"];
    wants = ["sys-subsystem-net-devices-enp2s0f0np0.device"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "-${pkgs.ethtool}/bin/ethtool -s enp2s0f0np0 speed 10000 duplex full autoneg off";
      RemainAfterExit = true;
    };
  };

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
      ];
    };
    users.josep = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.josep_password.path;
    };
    users.root = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7c4J3kFLiJYHqUh9zkybQu0pjOu8tyofUnsd67se9m mlab server key"
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
    port = 2283;
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

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
      inherit (inputs) nvim;
      inherit pkgs;
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

  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;
    environmentFiles = [config.sops.templates."homepage.env".path];

    settings = {
      title = "Mlab Dashboard";
      color = "zinc";
      theme = "dark";
      useEqualHeights = true;
      layout = {
        "Media & Audio" = {
          style = "row";
          columns = 3;
        };
        "Arr" = {
          style = "row";
          columns = 3;
        };
        "Tools" = {
          style = "row";
          columns = 2;
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
      {
        netdata = {
          url = "http://127.0.0.1:19999";
          states = ["cpu" "mem" "net"];
        };
      }
    ];

    services = [
      {
        "Media & Audio" = [
          {
            Navidrome = {
              icon = "navidrome";
              href = "https://music.marcel.cool";
              description = "Music Streamer";
              widget = {
                type = "navidrome";
                url = "http://127.0.0.1:4533";
                user = "{{HOMEPAGE_VAR_WEB_USER}}";
                salt = "{{HOMEPAGE_VAR_NAVIDROME_SALT}}";
                token = "{{HOMEPAGE_VAR_NAVIDROME_TOKEN}}";
              };
            };
          }
          {
            Jellyfin = {
              icon = "jellyfin";
              href = "https://jellyfin.marcel.cool";
              description = "Video Server";
              widget = {
                type = "jellyfin";
                url = "http://127.0.0.1:8096";
                key = "{{HOMEPAGE_VAR_JELLYFIN_API}}";
              };
            };
          }
          {
            Slskd = {
              icon = "soulseek";
              href = "https://slskd.marcel.cool";
              description = "Soulseek Client";
            };
          }
          {
            Soulbeet = {
              icon = "music";
              href = "https://soulbeet.marcel.cool";
              description = "Library Management";
            };
          }
        ];
      }
      {
        "Arr" = [
          {
            Chaptarr = {
              icon = "readarr";
              href = "https://chaptarr.marcel.cool";
              description = "Book Management";
            };
          }
          {
            Calibre = {
              icon = "book";
              href = "https://calibre.marcel.cool";
              description = "Book Library";
            };
          }
          {
            Audiobookshelf = {
              icon = "audiobookshelf";
              href = "https://audiobooks.marcel.cool";
              description = "Audiobook Server";
            };
          }
          {
            Sonarr = {
              icon = "sonarr";
              href = "https://sonarr.marcel.cool";
              widget = {
                type = "sonarr";
                url = "http://127.0.0.1:8989";
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
                url = "http://127.0.0.1:7878";
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
                url = "http://127.0.0.1:8686";
                key = "{{HOMEPAGE_VAR_LIDARR_API}}";
              };
            };
          }
          {
            Prowlarr = {
              icon = "prowlarr";
              href = "https://prowlarr.marcel.cool";
              widget = {
                type = "prowlarr";
                url = "http://127.0.0.1:9696";
                key = "{{HOMEPAGE_VAR_PROWLARR_API}}";
              };
            };
          }
          {
            qBittorrent = {
              icon = "qbittorrent";
              href = "https://qbit.marcel.cool";
              widget = {
                type = "qbittorrent";
                url = "http://127.0.0.1:8081";
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
                url = "http://127.0.0.1:8080";
                key = "{{HOMEPAGE_VAR_SABNZBD_API}}";
              };
            };
          }
          {
            Bazarr = {
              icon = "bazarr";
              href = "https://bazarr.marcel.cool";
              widget = {
                type = "bazarr";
                url = "http://127.0.0.1:6767";
                key = "{{HOMEPAGE_VAR_BAZARR_API}}";
              };
            };
          }
          {
            Seerr = {
              icon = "seerr";
              href = "https://seerr.marcel.cool";
              description = "Media Requests";
              widget = {
                type = "seerr";
                url = "http://127.0.0.1:5055";
                key = "{{HOMEPAGE_VAR_SEERR_API}}";
              };
            };
          }
          {
            Immich = {
              icon = "immich";
              href = "https://img.marcel.cool";
              description = "Photo Management";
              widget = {
                type = "immich";
                url = "http://127.0.0.1:2283";
                key = "{{HOMEPAGE_VAR_IMMICH_API}}";
                version = 2;
              };
            };
          }
        ];
      }
      {
        "Tools" = [
          {
            "Open WebUI" = {
              icon = "ollama";
              href = "https://ai.marcel.cool";
              description = "Local LLM Interface";
            };
          }
        ];
      }
    ];
  };

  system.stateVersion = "26.05";
}
