{
  _config,
  pkgs,
  inputs,
  ...
}: let
  terminalPackages = import ../../home/terminal-packages.nix {inherit pkgs;};
  stateVersion = "26.05";
in {
  system.stateVersion = stateVersion;

  # critical: prevents android from killing ssh when the screen is off
  android-integration.termux-wake-lock.enable = true;

  environment.packages =
    terminalPackages
    ++ (with pkgs; [
      openssh
      git
      vim
      fish
      inetutils
      iproute2
      mosh
    ]);

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
      };
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        "mlab" = {
          hostname = "ssh.marcel.cool";
          user = "root";
          identityFile = "~/.ssh/mlab_key";
          extraOptions = {
            IdentitiesOnly = "yes";
          };
        };
      };
      programs.bash = {
        enable = true;
        initExtra = ''
          source ${inputs.dots}/.bashrc
        '';
      };
    };
  };

  user.shell = "${pkgs.fish}/bin/fish";
}
