{
  pkgs,
  nix-on-droid,
  system,
  sshKeyPath,
}:
pkgs.stdenv.mkDerivation {
  name = "bootstrap-aarch64.zip";
  src = nix-on-droid.packages.${system}.bootstrapZip-aarch64;
  nativeBuildInputs = [pkgs.zip];
  unpackPhase = "true";

  installPhase = ''
    # Copy the official zipball to our output and make it writable
    cp $src $out
    chmod +w $out

    # Create the structure we want to inject
    mkdir -p home/.ssh
    mkdir -p home/.config/nixpkgs

    # 1. Inject your mlab SSH key
    cp ${sshKeyPath} home/.ssh/authorized_keys
    chmod 700 home/.ssh
    chmod 600 home/.ssh/authorized_keys

    # 2. Setup initial config matching your stateVersion
    cat > home/.config/nixpkgs/nix-on-droid.nix << 'EOF'
    { pkgs, ... }: {
      environment.packages = with pkgs; [ openssh git vim fish ];
      android-integration.termux-wake-lock.enable = true;
      user.shell = "${pkgs.fish}/bin/fish";
      system.stateVersion = "26.05";
    }
    EOF

    # 3. Bootstrapper profile
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
        # Ensure daemon is running on subsequent app launches
        pgrep sshd >/dev/null || sshd -p 8022
    fi

    # Drop into fish if it was successfully installed
    [ -x ~/.nix-profile/bin/fish ] && exec ~/.nix-profile/bin/fish
    EOF

    # Append the new home/ directory into the zip archive securely
    zip -r $out home/
  '';
}
