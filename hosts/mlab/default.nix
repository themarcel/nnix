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

  services.postgresql = {
    enable = true;
    authentication = lib.mkForce ''
      local all all trust
      host all all 127.0.0.1/32 trust
    '';
    ensureDatabases = ["navidrome"];
    ensureUsers = [
      {
        name = "navidrome";
        ensureDBOwnership = true;
      }
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
    ssl = true;
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
        authentication = {
          enabled = true;
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
      Auth = {
        Username = "admin";
        Password = "change-me-please";
      };
      MediaFolder = "/var/lib/slskd/music/share";
      DB = {
        Type = "postgres";
        Host = "127.0.0.1";
        Port = 5432;
        User = "navidrome";
        Password = "navidrome-pw";
        Database = "navidrome";
        SSLMode = "disable";
      };
    };
  };

  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/var/lib/slskd/music/share"
  ];

  networking = {
    hostName = "mlab";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        3000
        3001 # Immich UI
        2283 # Immich API
        5030 # slskd
        50300
        4533 # Navidrome
      ];
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  services.logrotate.checkConfig = false;
  zramSwap.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowAgentForwarding = true;
    };
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

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    enable = false; # not for now, we need more gpu in some way
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
