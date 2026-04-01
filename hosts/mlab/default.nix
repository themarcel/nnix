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

  systemd.tmpfiles.rules = [
    "d /var/lib/soulbeet 0755 root root -"
    "d /var/lib/slskd 0755 slskd slskd -"
    "d /var/lib/slskd/music 0755 slskd slskd -"
    "d /var/lib/slskd/music/downloads 0755 slskd slskd -"
    "d /var/lib/slskd/music/incompleted 0755 slskd slskd -"
    "d /var/lib/slskd/music/share 0755 slskd slskd -"
    "d /etc/slskd 0755 slskd slskd -"
  ];

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

  systemd.services.ddclient.after = ["nss-user-lookup.target"];

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
    passwordFile = "/var/lib/ddclient/cloudflare-token";
    domains = ["ssh.marcel.cool"];
    usev4 = "webv4, webv4=cloudflare";
    ssl = true;
  };

  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.soulbeet = {
    # image = "ghcr.io/terry90/soulbeet:latest";
    image = "docker.io/docccccc/soulbeet:latest";
    ports = ["127.0.0.1:9765:9765"];
    volumes = [
      "/var/lib/soulbeet:/data"
      "/var/lib/slskd/music/downloads:/downloads"
      "/var/lib/slskd/music/share:/music"
      # optional: mount a custom beets config if you have specific tagging needs
      # "/etc/soulbeet/beets_config.yaml:/config/config.yaml"
    ];
    environment = {
      DATABASE_URL = "sqlite:/data/soulbeet.db";
      SLSKD_URL = "http://127.0.0.1:5030";
      NAVIDROME_URL = "http://127.0.0.1:4533";
      SLSKD_API_KEY = "J:]DJid-;0^)ene)(7kA[0d<{";
      SOULBEET_URL = "https://soulbeet.marcel.cool";
      SECRET_KEY = "generate-a-long-random-string-here";
    };
    extraOptions = ["--network=host"]; # allows easy access to local slskd/navidrome
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "fd3b9e36-1dac-426c-9f99-31128df4f799" = {
        credentialsFile = "/var/lib/cloudflared/tunnel.json";
        default = "http_status:404";
        ingress = {
          "ai.marcel.cool" = "http://127.0.0.1:3000";
          "music.marcel.cool" = "http://127.0.0.1:4533";
          "slskd.marcel.cool" = "http://127.0.0.1:5030";
          "soulbeet.marcel.cool" = "http://127.0.0.1:9765";
        };
      };
    };
  };

  # services.caddy = {
  #   enable = true;
  #   virtualHosts."ai.marcel.cool" = {
  #     extraConfig = ''
  #       reverse_proxy 127.0.0.1:3000
  #     '';
  #   };
  #   virtualHosts = {
  #     # "photos.marcel.cool" = {
  #     #   extraConfig = ''
  #     #     @api path /api/*
  #     #     reverse_proxy @api 127.0.0.1:2283
  #     #     reverse_proxy 127.0.0.1:3001
  #     #   '';
  #     # };
  #     # "photos-server.marcel.cool" = {
  #     #   extraConfig = ''
  #     #     @api path /api/*
  #     #     reverse_proxy @api 127.0.0.1:2283
  #     #     reverse_proxy 127.0.0.1:3001
  #     #   '';
  #     # };
  #     "slskd.marcel.cool" = {
  #       extraConfig = ''
  #         reverse_proxy 127.0.0.1:5030
  #       '';
  #     };
  #     "music.marcel.cool" = {
  #       extraConfig = ''
  #         reverse_proxy 127.0.0.1:4533
  #       '';
  #     };
  #   };
  # };

  services.slskd = {
    enable = true;
    openFirewall = true;
    domain = null;
    user = "slskd";
    group = "slskd";
    environmentFile = "/etc/slskd/credentials.env";
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
          api_keys = {
            soulbeet = "J:]DJid-;0^)ene)(7kA[0d<{";
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
      MusicFolder = "/var/lib/slskd/music";
      DB = {
        Type = "postgres";
        Host = "/run/postgresql";
        User = "navidrome";
        Database = "navidrome";
      };
      # DB = {
      #   Type = "postgres";
      #   Host = "127.0.0.1";
      #   Port = 5432;
      #   User = "navidrome";
      #   Password = "navidrome-pw";
      #   Database = "navidrome";
      #   SSLMode = "disable";
      # };
    };
  };

  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/var/lib/slskd/music"
  ];

  networking = {
    hostName = "mlab";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        3000
        3001 # Immich UI
        2283 # Immich API
        5030 # slskd
        50300
        4533 # Navidrome
        9765 # Soulbeet
      ];
      extraCommands = ''
        # Allow traffic from Podman containers to the host
        iptables -A INPUT -i podman+ -p tcp --dport 5030 -j ACCEPT
        iptables -A INPUT -i podman+ -p tcp --dport 4533 -j ACCEPT
      '';
      trustedInterfaces = ["podman0"];
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  services.logrotate.checkConfig = false;
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

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
  ];
  environment.sessionVariables.NVIM_PROFILE = "minimal";

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];

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
  };

  users.groups.slskd = {};

  users.users.navidrome = {
    isSystemUser = true;
    group = "navidrome";
    extraGroups = ["slskd"];
    home = "/var/lib/navidrome";
    createHome = true;
  };

  users.groups.navidrome = {};

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
