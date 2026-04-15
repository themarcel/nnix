{
  _config,
  pkgs,
  inputs,
  ...
}: let
  stateVersion = "24.05";
  sshKey = builtins.readFile ../android/ssh.pub;
in {
  system.stateVersion = stateVersion;

  # critical: prevents android from killing ssh when the screen is off
  android-integration.termux-wake-lock.enable = true;

  # nix = {
  #   distributedBuilds = true;
  #   buildMachines = [
  #     {
  #       hostName = "nixos.local";
  #       sshUser = "marcel";
  #       systems = ["aarch64-linux" "x86_64-linux"];
  #       maxJobs = 4;
  #       speedFactor = 2;
  #       supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
  #       sshKey = "/data/data/com.termux.nix/files/home/.ssh/id_mlab";
  #     }
  #   ];
  #   extraOptions = ''
  #     builders-use-substitutes = true
  #   '';
  # };

  environment.packages = with pkgs; [
    openssh
    git
    vim
    fish
    inetutils
    iproute2
    mosh
    atuin
    direnv
    zoxide
    eza
    carapace
    procps
    bat
    rsync
    xargs
    sed
  ];

  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    OPENSSL_DIR = "${pkgs.openssl.out}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
    OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include";
  };

  home-manager = {
    backupFileExtension = "hm-bak";
    useGlobalPkgs = true;

    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      home.stateVersion = stateVersion;
      home.packages = with pkgs; [
        gnupg
      ];

      home = {
        file.".config/tmux".source = "${inputs.dots}/.config/tmux";
        file.".bash_aliases".source = "${inputs.dots}/.bash_aliases";
        file."clones/forks/xelabash".source = inputs.xelabash;
        file."scripts".source = "${inputs.dots}/scripts";
        file.".config/git".source = "${inputs.dots}/.config/git";
        file.".ssh/authorized_keys".text = sshKey;
        file.".ssh/sshd_config".text = ''
          Port 8022
          HostKey ${config.home.homeDirectory}/.ssh/ssh_host_ed25519_key
          AuthorizedKeysFile ${config.home.homeDirectory}/.ssh/authorized_keys
          StrictModes no
        '';
      };
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "mlab" = {
            hostname = "ssh.marcel.cool";
            user = "dev";
            identityFile = "~/.ssh/id_mlab";
            extraOptions = {
              IdentitiesOnly = "yes";
            };
          };
        };
      };
      programs.bash = {
        enable = true;
        initExtra = ''
          source ${inputs.dots}/.bashrc

          # Start SSHD with absolute paths to avoid 'Connection reset'
          if ! pgrep -x "sshd" >/dev/null; then
            # Ensure keys exist
            if [ ! -f /data/data/com.termux.nix/files/home/.ssh/ssh_host_ed25519_key ]; then
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /data/data/com.termux.nix/files/home/.ssh/ssh_host_ed25519_key -N "" -q
            fi

            # Start daemon using the full path to the config
            /data/data/com.termux.nix/files/home/.nix-profile/bin/sshd -f /data/data/com.termux.nix/files/home/.ssh/sshd_config
          fi
        '';
      };
    };
  };
}
