# Synology On-Demand Sync via rclone + Tailscale

On-demand mount of Synology shared folders over SFTP. Files appear locally without downloading; content fetches on open; new/modified files upload automatically.

## Prerequisites

- Tailscale installed on both the local machine and the Synology
- Both devices on the same Tailscale account (or shared via node sharing)
- SSH enabled on Synology (Control Panel → Terminal & SNMP → Enable SSH service)
- SFTP enabled on Synology (Control Panel → File Services → FTP → Enable SFTP service)

## Synology hostname

The Synology's Tailscale hostname is `nephila.tail491f36.ts.net`. Find it with `tailscale status`.

This hostname is on the personal Tailscale account (stevegrandpre@). If the local machine is on the work Tailscale account, share the Synology node into the work tailnet:

1. Log into https://login.tailscale.com/admin/machines with the personal account
2. Find the Synology → `...` menu → Share → enter work email
3. Accept the share invite from the work account

The shared node then appears in the work tailnet — only visible to your account, not coworkers.

## Install rclone

The Ubuntu/apt version is outdated and has SSH key parsing bugs. Install from the official source:

```bash
curl -fsSL https://rclone.org/install.sh | sudo bash
```

Also ensure FUSE is installed:

```bash
sudo apt install fuse3
```

## Configure rclone remote

```bash
rclone config
```

- New remote, name: `nephila`
- Type: `sftp`
- Host: `nephila.tail491f36.ts.net`
- User: `sgrandpre`
- For auth, use password (not SSH key — see gotchas below)

When prompted for the password, let rclone obscure it. Or set it afterward:

```bash
rclone obscure  # type password, get obscured string
```

Then edit `~/.config/rclone/rclone.conf`:

```ini
[nephila]
type = sftp
host = nephila.tail491f36.ts.net
user = sgrandpre
pass = <obscured password>
shell_type = unix
```

Test:

```bash
rclone lsd nephila:/
```

You should see shared folders (spark, audiobooks, eBooks, etc.). The share paths are at the root (`/spark`), not under `/volume1/`.

## Create mount points

```bash
mkdir -p ~/Synology/spark ~/Synology/audiobooks ~/Synology/eBooks
```

## Set up systemd user services

Create a service file per mount in `~/.config/systemd/user/`. Example for `spark`:

`~/.config/systemd/user/rclone-synology-spark.service`:

```ini
[Unit]
Description=rclone mount for Synology spark
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=rclone mount nephila:/spark %h/Synology/spark \
  --vfs-cache-mode writes \
  --vfs-cache-max-age 24h \
  --dir-cache-time 5m \
  --allow-non-empty
ExecStop=/bin/fusermount3 -u %h/Synology/spark
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

Repeat for audiobooks (`nephila:/audiobooks` → `%h/Synology/audiobooks`) and eBooks (`nephila:/eBooks` → `%h/Synology/eBooks`).

Enable and start:

```bash
systemctl --user daemon-reload
systemctl --user enable --now rclone-synology-spark.service
systemctl --user enable --now rclone-synology-audiobooks.service
systemctl --user enable --now rclone-synology-ebooks.service
```

Enable linger so services start at boot without requiring login:

```bash
sudo loginctl enable-linger $USER
```

## Gotchas

### Don't use SSH key auth with Synology

Synology DSM uses ACLs that make home directories appear world-writable (`drwxrwxrwx+`) in POSIX permissions. OpenSSH's `StrictModes` (enabled by default) rejects publickey auth when the home directory, `~/.ssh`, or `authorized_keys` are group/world-writable. The key gets rejected silently — SSH falls back to password auth (via KDE Wallet), so it looks like the key works, but it doesn't.

Fixing this requires `StrictModes no` in `/etc/ssh/sshd_config` on the Synology, but modifying sshd_config and reloading sshd on Synology is risky — `kill -HUP` can take down sshd entirely and DSM's service manager won't auto-restart it. Password auth via rclone's obscured password storage is simpler and reliable.

### Don't use the apt version of rclone

Ubuntu's packaged rclone (v1.60.x-DEV as of 26.04) can't parse OpenSSH-format private keys. Always install from https://rclone.org/install.sh.

### SFTP must be enabled separately from SSH

SSH (Control Panel → Terminal & SNMP) and SFTP (Control Panel → File Services → FTP) are independent toggles in DSM. rclone needs SFTP.

### Share paths

SFTP paths on Synology are at the root (`/spark`, `/audiobooks`), not under `/volume1/`.
