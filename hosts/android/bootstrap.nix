{
  pkgs,
  nix-on-droid,
  system,
  targetSystem,
  sshKeyPath,
  flakeSource,
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
      cp ${sshKeyPath} home/.ssh/authorized_keys
      chmod 700 home/.ssh
      chmod 600 home/.ssh/authorized_keys

      # 1. Copy your entire flake repository to the phone
      mkdir -p home/nix
      cp -r ${flakeSource}/* home/nix/
      chmod -R +w home/nix # Nix store paths are read-only, so we fix permissions

      # 2. Tell the bootstrap to build from your local flake
      cat > home/.bash_profile << 'EOF'
      [ -f ~/.bashrc ] && source ~/.bashrc

      if [ ! -f ~/.nix-profile/bin/sshd ]; then
          echo "=> Installing your full Nix-on-Droid Flake..."

          # Change "android" to whatever you named your configuration in flake.nix
          nix-on-droid switch --flake ~/nix#android

          source /etc/profile
          sshd -p 8022
      else
          source /etc/profile
          pgrep sshd >/dev/null || sshd -p 8022
      fi

      [ -x ~/.nix-profile/bin/fish ] && exec ~/.nix-profile/bin/fish
      EOF

      zip -r $out home/
    '';
  }
