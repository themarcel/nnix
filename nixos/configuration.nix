{
  config,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  programs.mosh.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.efi.canTouchEfiVariables = true;
  nix.settings = {
    max-jobs = "auto";
    # cores = 0; # Use all cores
    keep-outputs = true;
    keep-derivations = true;
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    substituters = [
      "https://nix-community.cachix.org"
      "https://cache.nixos.org"
      # "https://hyprland.cachix.org"
      "https://marcelarie.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "marcelarie.cachix.org-1:loFQMIgWqiIgfRixHOrEwbGADvFYu8RJXF6jqL0HUy8="
    ];
    trusted-users = [
      "root"
      "marcel"
    ];
    connect-timeout = 15;
  };

  services.protonmail-bridge = {
    enable = true;
  };

  services.mpd = {
    enable = true;
    user = "marcel";
    startWhenNeeded = true;
    settings = {
      music_directory = "/home/marcel/techno-electronica/";
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Output";
        }
      ];
    };

    # Optional:
    # network.listenAddress = "any"; # if you want to allow non-localhost connections
    # network.startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket
  };

  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
  };

  services.cachix-watch-store = {
    enable = true;
    cacheName = "marcelarie";
    cachixTokenFile = config.sops.secrets.cachix_token.path;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  networking.hostName = "nixos";
  services.fwupd.enable = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          ReconnectAttempts = "0";
        };
      };
    };
  };
  services.mullvad-vpn.enable = true;
  services.flatpak.enable = true;

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [networkmanager-openvpn];
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  # networking.enableIPv6 = false;

  # Set your time zone.
  time.timeZone = "Europe/Madrid";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  # services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.desktopManager.plasma6.enable = true;
  programs.hyprland.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [];

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.nzbget = {
    enable = true;
  };

  systemd.services.slskd.serviceConfig.ProtectHome = lib.mkForce false;

  systemd.tmpfiles.rules = [
    "d /home/${username}/music/downloads 0755 ${username} users -"
    "d /home/${username}/music/incompleted 0755 ${username} users -"
    "d /home/${username}/music/share 0755 ${username} users -"
  ];

  services.slskd = {
    enable = true;
    openFirewall = true;
    domain = null;
    user = username;
    group = "users";
    environmentFile = config.sops.templates."slskd.env".path;
    settings = {
      directories = {
        downloads = "/home/${username}/music/downloads";
        incomplete = "/home/${username}/music/incompleted";
      };
      shares = {
        directories = ["/home/${username}/music/share"];
      };
      soulseek = {
        listen_port = 50300;
        username = "mwallace";
      };
      web = {
        port = 5030;
        authentication = {
          username = username;
        };
      };
      global = {
        upload.slots = 10;
        download.slots = 10;
      };
    };
  };

  # services.ollama = {
  #   enable = true;
  # };

  systemd.services.ollama.environment = {
    OLLAMA_CONTEXT_LENGTH = "32768";
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KEEP_ALIVE = "24h";
  };

  # deprecated in favor of ai.marcel.cool
  # services.open-webui = {
  #   enable = true;
  #   port = 8080;
  #   environment = {
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
  #     WEBUI_AUTH = "False";
  #   };
  # };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  # services.udev.packages = [pkgs.mixxx];
  musnix.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  security = {
    # If enabled, pam_wallet will attempt to automatically unlock the user's default KDE wallet upon login.
    # If the user has no wallet named "kdewallet", or the login password does not match their wallet password,
    # KDE will prompt separately after login.
    pam = {
      services = {
        marcel = {
          kwallet = {
            enable = true;
            package = pkgs.kdePackages.kwallet-pam;
          };
        };
        # Add GNOME keyring support for KDE applications
        login = {
          enableGnomeKeyring = true;
        };
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.marcel = {
    isNormalUser = true;
    description = "marcel";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "docker"
    ];
    packages = with pkgs; [
      kitty
      # kdePackages.kate
      #  thunderbird
    ];
  };

  services.dbus.enable = true;
  # Use KWallet instead of GNOME keyring for KDE Plasma
  services.gnome.gnome-keyring.enable = false;
  programs.seahorse.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
      theme = "breeze";
    };
    sessionPackages = [
      pkgs.hyprland
      pkgs.niri
    ];
    defaultSession = "hyprland";
    autoLogin = {
      enable = false;
      user = "marcel";
    };
  };

  # programs.firefox = {
  #   enable = true;
  #
  #   policies = {
  #     Preferences = {
  #       "extensions.pocket.enabled" = {
  #         Value = false;
  #         Status = "locked";
  #       };
  #       "ui.key.menuAccessKeyFocuses" = {
  #         Value = false;
  #         Status = "locked";
  #       };
  #       "browser.tabs.allowTabDetach" = {
  #         Value = false;
  #         Status = "locked";
  #       };
  #       "alerts.useSystemBackend" = {
  #         Value = true;
  #         Status = "locked";
  #       };
  #     };
  #   };
  # };

  environment.systemPackages = with pkgs; [
    vim
    neovim
    wget
    # mullvad-vpn
    # mullvad
    git
    gnumake
    usbutils
    networkmanagerapplet
    glib
    gcc
    gnupg
    pass
    openssl
    openvpn
    sbc
    chromium
    (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
      [General]
      background=/etc/sddm/black.png
    '')
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  sops = {
    defaultSopsFile = ../secrets/nixos.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    secrets = {
      "SLSKD_SLSK_USERNAME" = {owner = username;};
      "SLSKD_SLSK_PASSWORD" = {owner = username;};
      "SLSKD_SOULSEEK_PASSWORD" = {owner = username;};
      "SLSKD_WEB_USERNAME" = {owner = username;};
      "SLSKD_WEB_PASSWORD" = {owner = username;};
      "SLSKD_USERNAME" = {owner = username;};
      "SLSKD_PASSWORD" = {owner = username;};
      "cachix_token" = {owner = username;};
    };

    templates."slskd.env" = {
      content = ''
        SLSKD_SLSK_USERNAME="${config.sops.placeholder.SLSKD_SLSK_USERNAME}"
        SLSKD_SLSK_PASSWORD="${config.sops.placeholder.SLSKD_SLSK_PASSWORD}"
        SLSKD_SOULSEEK_PASSWORD="${config.sops.placeholder.SLSKD_SOULSEEK_PASSWORD}"
        SLSKD_WEB_USERNAME="${config.sops.placeholder.SLSKD_WEB_USERNAME}"
        SLSKD_WEB_PASSWORD="${config.sops.placeholder.SLSKD_WEB_PASSWORD}"
        SLSKD_USERNAME="${config.sops.placeholder.SLSKD_USERNAME}"
        SLSKD_PASSWORD="${config.sops.placeholder.SLSKD_PASSWORD}"
      '';
      owner = username;
    };
  };

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;
  networking.networkmanager.wifi.powersave = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
