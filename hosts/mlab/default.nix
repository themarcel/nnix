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
      "jackett_api_key" = {};
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
    };

    templates."tunnel.json" = {
      content = config.sops.placeholder.cloudflared_tunnel_json;
      owner = "cloudflared";
      group = "cloudflared";
    };

    templates."jackett.json" = {
      content = ''{"api_key":"${config.sops.placeholder.jackett_api_key}","tracker_first":false,"url":"http://127.0.0.1:9117","thread_count":20}'';
      owner = "qbittorrent";
      group = "qbittorrent";
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
  };

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

  services.sonarr = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/soulbeet 0755 root root -"
    "d /var/lib/slskd 0755 slskd slskd -"
    "d /var/lib/slskd/music 0755 slskd slskd -"
    "d /var/lib/slskd/music/downloads 0755 slskd slskd -"
    "d /var/lib/slskd/music/incompleted 0755 slskd slskd -"
    "d /var/lib/slskd/music/share 0755 slskd slskd -"
    "d /etc/slskd 0755 slskd slskd -"
    "d /var/lib/media 0775 qbittorrent media -"
    "d /var/lib/media/downloads 0775 qbittorrent media -"
    "d /var/lib/media/tv 0775 qbittorrent media -"
    "d /var/lib/media/movies 0775 qbittorrent media -"
    "d /var/lib/media/tv 0775 sonarr media -"
    "d /var/lib/media/downloads 0775 sonarr media -"
    "d /var/lib/sabnzbd 0750 sabnzbd sabnzbd -"
    "f /var/lib/sabnzbd/sabnzbd.ini 0640 sabnzbd sabnzbd -"
  ];
  systemd.services.ddclient.after = ["nss-user-lookup.target"];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
    webuiPort = 8081;
  };

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
    usev4 = "webv4, webv4=cloudflare";
    ssl = true;
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  sops.templates."soulbeet.env".content = ''
    # Connection to Slskd
    SLSKD_URL=http://127.0.0.1:5030
    SLSKD_API_KEY=${config.sops.placeholder.slskd_api_key}

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

  virtualisation.oci-containers.containers.soulbeet = {
    image = "docker.io/docccccc/soulbeet:latest";
    volumes = [
      "/var/lib/soulbeet:/data"
      "/var/lib/slskd/music/downloads:/var/lib/slskd/music/downloads"
      "/var/lib/slskd/music/share:/music"
      # optional: mount a custom beets config if you have specific tagging needs
      # "/etc/soulbeet/beets_config.yaml:/config/config.yaml"
    ];
    environmentFiles = [
      config.sops.templates."soulbeet.env".path
    ];
    extraOptions = ["--network=host"]; # allows easy access to local slskd/navidrome
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
          "jackett.marcel.cool" = "http://127.0.0.1:9117";
          "sonarr.marcel.cool" = "http://127.0.0.1:8989";
          "sabnzbd.marcel.cool" = "http://127.0.0.1:8080";
        };
      };
    };
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
          enabled = true;
          key = "slskdAPIkey9988776655aabbccdd";
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
    interfaces = {
      enp2s0f0np0 = {
        useDHCP = true;
      };
      enp2s0f1np1 = {
        useDHCP = true;
      };
    };
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80 # nginx catch-all
        3000
        3001 # Immich UI
        2283 # Immich API
        5030 # slskd
        50300
        4533 # Navidrome
        9765 # Soulbeet
        8096 # Jellyfin HTTP
        8081 # qBittorrent WebUI
        8080 # SABnzbd
        9117 # Jackett
        8989 # Sonarr
      ];
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
  };

  services.sabnzbd = {
    enable = true;
    openFirewall = true;
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
      packages = with pkgs; [
        neovim
        eza
        zoxide
        fd
        fzf
        bat
        bottom
        starship
        direnv
      ];
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
  };

  services.ollama = {
    enable = true;
  };

  services.immich = {
    enable = false; # disable for now

    settings = {
      server = {
        host = "0.0.0.0"; # frontend
        port = 3001;
      };
      api = {
        host = "0.0.0.0";
        port = 2283;
      };
    };
  };

  services.jackett = {
    enable = true;
    openFirewall = true;
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
        stateVersion = "25.11";
        sessionVariables.NVIM_PROFILE = "minimal";
      };
      imports = [inputs.nvim.homeManagerModules.default];
    };
  };

  system.stateVersion = "25.11";
}
