{
  _config,
  pkgs,
  inputs,
  ...
}: let
  stateVersion = "24.05";
in {
  system.stateVersion = stateVersion;

  # critical: prevents android from killing ssh when the screen is off
  android-integration.termux-wake-lock.enable = true;

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
        file.".ssh/sshd_config".text = ''
          Port 8022
          HostKey ~/.ssh/ssh_host_ed25519_key
          AuthorizedKeysFile ~/.ssh/authorized_keys
          StrictModes no
        '';
      };
      programs.ssh = {
        enable = true;
      };
      programs.bash = {
        enable = true;
        initExtra = ''
          source ${inputs.dots}/.bashrc

          # Auto-start SSH daemon safely
          if ! pgrep -x "sshd" >/dev/null; then
            # Generate host key if it doesn't exist
            if [ ! -f ~/.ssh/ssh_host_ed25519_key ]; then
              ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f ~/.ssh/ssh_host_ed25519_key -N "" -q
            fi
            # Start the daemon
            ~/.nix-profile/bin/sshd -f ~/.ssh/sshd_config
          fi
        '';
      };
    };
  };
}
