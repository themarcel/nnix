This checklist covers the transition from your 250GB drive to your new 2TB
drive. Since you are using **NixOS**, the goal is to back up the "state"
(databases and keys) and your configuration files.

### 📋 Migration Todo List

- [ ] **Stop Services:** Stop `postgresql`, `navidrome`, and `slskd` before backing up to ensure database integrity.
- [ ] **Back up Configuration:** Save your `configuration.nix` and `flake.nix` (if using flakes).
- [ ] **Back up Stateful Data:** Copy the `/var/lib` directories for your apps.
- [ ] **Back up Secrets:** Copy Cloudflare tokens and `credentials.env` files.
- [ ] **Verify Backup:** Ensure the files are actually on your laptop and readable.
- [ ] **Physical Swap:** Power down, swap the NVMe drives.
- [ ] **Fresh Install:** Boot from NixOS Live USB and partition the 2TB drive.
- [ ] **Generate New Hardware Config:** Run `nixos-generate-config` to get the new UUIDs.
- [ ] **Restore Data:** Move your `/var/lib` folders and secrets back to the MS-01.
- [ ] **Deploy:** Copy your old `configuration.nix` back and run `nixos-rebuild switch`.

---

### 💾 Backup Commands (Run from your Laptop)

Using `rsync` is highly recommended over `scp` because it preserves file
permissions and handles large transfers better.

**Note:**
Replace `dev` with your server username and `192.168.x.x` with your MS-01's local IP.

#### 1. Create a backup folder on your laptop

```bash
mkdir -p ~/ms01-backup/var-lib ~/ms01-backup/etc
```

#### 2. Stop services on the MS-01 (Run on Server first)

```bash
sudo systemctl stop postgresql navidrome slskd cloudflared
```

#### 3. Pull the data to your laptop (Run on Laptop)

This command pulls all critical directories identified in your config.

```bash
# Backup NixOS Configurations
rsync -avzP dev@192.168.x.x:/etc/nixos/ ~/ms01-backup/etc/nixos/

# Backup Cloudflare & DDNS Secrets
sudo rsync -avzP dev@192.168.x.x:/var/lib/cloudflared/ ~/ms01-backup/var-lib/cloudflared/
sudo rsync -avzP dev@192.168.x.x:/var/lib/ddclient/ ~/ms01-backup/var-lib/ddclient/

# Backup App Data & Databases
sudo rsync -avzP dev@192.168.x.x:/var/lib/postgresql/ ~/ms01-backup/var-lib/postgresql/
sudo rsync -avzP dev@192.168.x.x:/var/lib/navidrome/ ~/ms01-backup/var-lib/navidrome/
sudo rsync -avzP dev@192.168.x.x:/var/lib/slskd/ ~/ms01-backup/var-lib/slskd/
sudo rsync -avzP dev@192.168.x.x:/var/lib/soulbeet/ ~/ms01-backup/var-lib/soulbeet/

# Backup manual secrets
sudo rsync -avzP dev@192.168.x.x:/etc/slskd/ ~/ms01-backup/etc/slskd/
```

---

### 📥 Restore Commands (After New Install)

Once you have NixOS installed on the 2TB drive and have run the initial
`nixos-generate-config`, push the data back from your laptop:

```bash
# Push everything back to the server
sudo rsync -avzP ~/ms01-backup/var-lib/ dev@192.168.x.x:/var/lib/
sudo rsync -avzP ~/ms01-backup/etc/slskd/ dev@192.168.x.x:/etc/slskd/
```

### ⚠️ Final Step: Fix Permissions

After restoring to the new drive, the User IDs (UIDs) might have shifted. Before
running your first `rebuild`, it is a good idea to ensure the folders are owned
by the correct service users again:

```bash
sudo chown -R postgres:postgres /var/lib/postgresql
sudo chown -R navidrome:navidrome /var/lib/navidrome
sudo chown -R slskd:slskd /var/lib/slskd
```

Now you can run `sudo nixos-rebuild switch` and everything should come back online!
