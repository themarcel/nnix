# VPS Deployment with nixos-anywhere

## Prerequisites

1. VPS running Linux (x86_64) with kexec support
2. Root SSH access to the VPS
3. At least 1GB RAM available
4. SSH key configured in the configuration
5. DNS records pointing to your VPS IP (for ai.marcel.cool)

## Configuration Files

- **`hosts/vps/default.nix`** - Main NixOS configuration
- **`hosts/vps/disk-config.nix`** - Disk partitioning layout
- **`hosts/vps/hardware-configuration.nix`** - Hardware config (generated during install)

## Disk Configuration

The disk configuration uses `/dev/sda` by default. **Verify your VPS disk device** before deploying:

```bash
# SSH into your VPS and run:
lsblk
```

If your disk is not `/dev/sda` (common alternatives: `/dev/vda`, `/dev/nvme0n1`), update `disk-config.nix` accordingly.

## Initial Deployment (First Time)

### 1. Update flake.lock

```bash
nix flake lock
```

### 2. Test the configuration locally (optional but recommended)

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#vps --vm-test
```

### 3. Deploy to VPS

** WARNING: This will completely erase the VPS and install NixOS**

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --target-host root@<VPS_IP> \
  -i ~/.ssh/public_vps_ssh_key \
  --generate-hardware-config nixos-generate-config ./hosts/vps/hardware-configuration.nix
```

Replace `<VPS_IP>` with your VPS's IP address and ~/.ssh/public_vps_ssh_key with the real private key

## Subsequent Deployments

After the initial deployment, you can update the VPS without regenerating hardware config:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#vps \
  --target-host root@<VPS_IP> \
  -i ~/.ssh/public_vps_ssh_key
```

## Troubleshooting

### SSH Host Key Changed

After installation, you'll see a warning about changed host keys. Fix it with:

```bash
ssh-keygen -R <VPS_IP>
```

### Connection Issues

- Ensure SSH port 22 is open in your VPS firewall
- Verify your SSH key has been added to the root user in the configuration
- Check that you have root access or passwordless sudo on the target VPS

## Post-Deployment

Once deployed, services will be available:

- Open WebUI: http://ai.marcel.cool (via Caddy reverse proxy)
- SSH: `ssh root@<VPS_IP>`

To update the VPS configuration after deployment:

```bash
nixos-rebuild switch --flake .#vps --target-host root@<VPS_IP>
```
