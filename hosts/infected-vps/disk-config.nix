# Disk configuration for VPS deployment using nixos-anywhere
# This configuration sets up a standard GPT partition table with EFI support
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # BIOS boot partition for GRUB
            boot = {
              size = "1M";
              type = "EF02"; # BIOS boot partition
            };
            # EFI System Partition
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "umask=0077"
                ];
              };
            };
            # Root partition using all remaining space
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
