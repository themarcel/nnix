{config, ...}: {
  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
    PubkeyAcceptedKeyTypes ssh-ed25519
    ServerAliveInterval 60
    IPQoS throughput
    IdentityFile ~/.ssh/my-nixbuild-key
  '';

  nix = {
    distributedBuilds = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        systems = ["x86_64-linux" "aarch64-linux"];
        maxJobs = 100;
        supportedFeatures = ["benchmark" "big-parallel"];
      }
    ];
  };
}
