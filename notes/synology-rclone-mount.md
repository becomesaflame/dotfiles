# Synology On-Demand Sync via rclone + Tailscale

On-demand mount of Synology shared folders over SFTP. Files appear locally without downloading; content fetches from the NAS on open and is then cached on local disk (so re-reads are instant); new/modified files upload automatically.

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

The Ubuntu/apt rclone (v1.60.x-DEV as of 26.04) is years out of date and has **two** bugs that bite this setup, so don't use it:

- It can't parse OpenSSH-format private keys.
- Its VFS cache downloader **stalls forever reading a large file (>~128 MB) through the mount** — small reads and direct `rclone copy` work, but `cat`/apps reading a big file through the mount hang with no error logged. Fixed in current rclone.

Install the current rclone to `/usr/local/bin`, kept separate from the apt-managed `/usr/bin/rclone` so package updates can't clobber it:

```bash
curl -fsSL -o /tmp/rclone.zip https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip -q /tmp/rclone.zip -d /tmp/rclone-current
sudo install -m 0755 /tmp/rclone-current/*/rclone /usr/local/bin/rclone
/usr/local/bin/rclone version   # confirm (currently v1.74.x)
```

The systemd units below call `/usr/local/bin/rclone` by explicit path. **Updates are manual** — re-run the above to upgrade; `apt` won't help.

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
- Auth: password (see the SSH-key gotcha below)

When prompted for the password, let rclone obscure it (or run `rclone obscure` to get the string). Then `~/.config/rclone/rclone.conf`:

```ini
[nephila]
type = sftp
host = nephila.tail491f36.ts.net
user = sgrandpre
pass = <obscured password>
shell_type = unix
disable_hashcheck = true
```

`disable_hashcheck = true` is **required** — without it rclone deletes its own uploads (see the hashcheck gotcha below).

Test:

```bash
rclone lsd nephila:/
```

You should see shared folders (spark, audiobooks, eBooks, etc.). SFTP share paths are at the root (`/spark`), not under `/volume1/`.

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
# Wait until the Synology's SSH port is reachable before starting, so the mount
# doesn't thrash at boot/resume before Tailscale is up.
ExecStartPre=/usr/bin/bash -c 'for i in $(seq 1 30); do timeout 3 bash -c "exec 3<>/dev/tcp/nephila.tail491f36.ts.net/22" 2>/dev/null && exit 0; sleep 2; done; exit 0'
ExecStart=/usr/local/bin/rclone mount nephila:/spark %h/Synology/spark \
  --vfs-cache-mode full \
  --vfs-cache-max-age 8760h \
  --vfs-cache-max-size 1T \
  --dir-cache-time 24h \
  --allow-non-empty \
  --timeout 60s \
  --contimeout 15s \
  --sftp-idle-timeout 30s \
  --low-level-retries 10
ExecStop=/bin/fusermount3 -uz %h/Synology/spark
Restart=always
RestartSec=10
TimeoutStopSec=20

[Install]
WantedBy=default.target
```

Notes on the flags:

- `--vfs-cache-mode full` caches read files on local disk (`~/.cache/rclone`) so opening a file a second time is instant and offline-capable. (The older `writes` mode only cached *uploads* and re-streamed every read.)
- `--vfs-cache-max-size 1T` caps each mount's cache. It's **per mount**, so three mounts can use up to 3×1T — watch free space on `~` (lives on `/home`).
- `--vfs-cache-max-age 8760h` keeps cached files ~1 year.
- Writes are buffered to the cache and uploaded with automatic retry, so a file created while the NAS is briefly unreachable uploads once it returns — *provided the mount is already running*. rclone's SFTP backend can't establish a brand-new mount while the NAS is down (it connects at mount time).

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

### `disable_hashcheck = true` is required (or rclone deletes its own uploads)

After uploading, rclone verifies the file by running `md5sum` over an SSH shell. On Synology the SFTP service and the SSH shell see *different* absolute paths — SFTP is rooted at the share (`/audiobooks/...`) while the shell sees the real volume path (`/volume1/audiobooks/...`). So the post-upload `md5sum` runs against a path that doesn't exist, errors out, and rclone concludes the transfer was "corrupted on transfer" and **deletes the file it just uploaded** (`SetModTime` fails the same way). Set `disable_hashcheck = true` on the remote to skip the shell hash check. (SFTP size verification still applies.)

### Don't let Synology Drive sync the same folders rclone writes to

If Synology Drive Server / ShareSync is two-way-syncing a shared folder that rclone also writes into, it treats rclone's atomic writes as conflicts and quarantines every uploaded file into a `<name>_<account>_<timestamp>_Conflict/` directory. This silently produced ~1,900 conflict directories (~2 TB of duplicate copies) on the audiobooks share. Fix: disable Synology Drive sync on rclone-managed shares, **or** make it one-way (DS → peer) — a one-way sync never creates conflict copies. Never have two writers on one folder. (To clean up an existing mess, on the NAS: `find /volume1/<share> -depth -type d -name '*_Conflict' -exec rm -rf {} +`.)

### Use current rclone — old versions stall on large reads

The apt rclone (v1.60) hangs forever reading files larger than ~128 MB *through the mount* (VFS cache-downloader bug); small reads and direct `rclone copy` are unaffected. If a large read hangs at a fixed size with no error in the logs, check `rclone version` — current rclone (v1.74+) reads them fine. See Install above.

### SSH key auth *can* work — fix the home-dir perms

rclone here uses password auth (simplest, and what's configured). If you want SSH **key** auth too (e.g. for a maintenance shell), `ssh-copy-id` alone isn't enough: Synology home dirs are group/world-writable by default, so OpenSSH `StrictModes` silently rejects the key and falls back to password. You do **not** need `StrictModes no` — just tighten the perms on the Synology:

```bash
ssh sgrandpre@nephila 'chmod 700 ~ ~/.ssh && chmod 600 ~/.ssh/authorized_keys'
```

Verify with `ssh -v` that the server accepts the offered key (not "Permission denied (publickey,password)").

### Hibernation: dead mounts block the freeze

If the NAS/network goes away, processes touching the mount get stuck in uninterruptible (D) state, and the kernel then fails to freeze tasks during hibernation ("Freezing of tasks failed (N tasks refusing to freeze)"). A root sleep hook at `/usr/lib/systemd/system-sleep/50-rclone-synology` lazy-unmounts and stops the rclone services before sleep and restarts them on resume. See `notes/hibernation.md`.

### Copying large files to a phone: use KDE Connect, not MTP/USB

MTP (USB) writes of large files fail on Linux — `kio_mtp`/Dolphin and `go-mtpfs` both choke on big files (small files are fine), and a failed write wedges the MTP session. Use KDE Connect over wifi to send a large file to an Android phone instead. (Also: Android file managers can't move a file into a folder whose name contains a `:` — rename the folder without the colon first.)

### SFTP must be enabled separately from SSH

SSH (Control Panel → Terminal & SNMP) and SFTP (Control Panel → File Services → FTP) are independent toggles in DSM. rclone needs SFTP.

### Share paths

SFTP paths on Synology are at the root (`/spark`, `/audiobooks`), not under `/volume1/`. (The SSH *shell*, by contrast, sees `/volume1/...` — this mismatch is what breaks hashcheck above.)
