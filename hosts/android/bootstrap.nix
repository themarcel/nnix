{
  pkgs,
  nix-on-droid,
  system,
  targetSystem,
  sshKeyPath,
  ...
}: let
  targetArch = pkgs.lib.removeSuffix "-linux" targetSystem;
in
  pkgs.stdenv.mkDerivation {
    name = "bootstrap-${targetArch}.zip";
    src = nix-on-droid.packages.${system}."bootstrapZip-${targetArch}";

    nativeBuildInputs = [pkgs.zip];
    unpackPhase = "true";

    installPhase = ''
      cp $src/*.zip $out
      chmod +w $out

      mkdir -p home/.ssh
      mkdir -p home/.config/nixpkgs

      cp ${sshKeyPath} home/.ssh/authorized_keys
      chmod 700 home/.ssh
      chmod 600 home/.ssh/authorized_keys

      cat > home/.config/nixpkgs/nix-on-droid.nix << 'EOF'
      { pkgs, ... }: {
        environment.packages = with pkgs; [ openssh git vim fish ];
        android-integration.termux-wake-lock.enable = true;
        user.shell = "${pkgs.fish}/bin/fish";
        system.stateVersion = "26.05";
      }
      EOF

      cat > home/.bash_profile << 'EOF'
      [ -f ~/.bashrc ] && source ~/.bashrc

      if ! command -v sshd >/dev/null 2>&1; then
          echo "========================================="
          echo "=> Initializing Nix-on-Droid..."
          echo "=> Installing OpenSSH and Fish..."
          echo "========================================="

          nix-on-droid switch

          echo "=> Generating SSH host keys..."
          ssh-keygen -A

          echo "=> Starting SSH daemon on port 8022..."
          sshd -p 8022
      else
          pgrep sshd >/dev/null || sshd -p 8022
      fi

      [ -x ~/.nix-profile/bin/fish ] && exec ~/.nix-profile/bin/fish
      EOF

      zip -r $out home/
    '';
  }
