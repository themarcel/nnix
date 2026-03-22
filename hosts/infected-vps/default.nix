{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
  };

  services.caddy = {
    enable = true;
    virtualHosts."ai.marcel.cool" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:3000
      '';
    };
  };

  networking = {
    hostName = "marcel-cool-vps";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        3000
      ];
    };
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.tmp.cleanOnBoot = true;

  services.logrotate.checkConfig = false;
  zramSwap.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
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
        git
        neovim
        eza
        zoxide
        fd
        fzf
        bat
        bottom
        duf
        jq
        ripgrep
        tmux
        starship
        direnv
      ];
    };

    users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2bNnjQbOyc2j6yWvDbwfMLdv1Ej6/6QA77C1M05Awv"
    ];
  };

  services.ollama = {
    enable = false; # not for now, we need more gpu in some way
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
        stateVersion = "24.11";
        sessionVariables.NVIM_PROFILE = "minimal";
      };
      imports = [inputs.nvim.homeManagerModules.default];
    };
  };

  system.stateVersion = "24.11";
}
