# Hibernation (Ubuntu 26.04 / KDE Plasma 6, host: phiddipus)

Hibernation works at the hardware level — `resume=UUID=...` on the kernel cmdline points at the 96 GB LVM swap (`ubuntu--vg-swap`), which is plenty for the 93 GB RAM. Two separate problems made it look broken; both are fixed.

## 1. Battery draining "in hibernation" — it was suspending instead

PowerDevil had **suspend-then-hibernate only on the Battery and Low-Battery profiles**, not on AC. So sleeping while plugged in did a plain suspend-to-RAM; unplug and walk away, and it quietly drained until dead.

Fix — give the AC profile the same sleep mode. In `~/.config/powerdevilrc`, under `[AC][SuspendAndShutdown]`:

```ini
SleepMode=3
```

`SleepMode=3` is "Sleep then hibernate" (1 = plain suspend). Apply with `systemctl --user restart plasma-powerdevil.service`, or set it in System Settings → Power Management → On AC Power → sleep mode. (This file is a regular file, not symlinked into the dotfiles repo.)

Check what a given sleep actually did:
```bash
journalctl | grep "Performing sleep operation"
```

## 2. Hibernation aborting: "Freezing of tasks failed"

Hibernation failed with `Freezing of tasks failed (N tasks refusing to freeze)` when the network was down: processes touching the rclone Synology mounts were stuck in uninterruptible (D) state and couldn't be frozen, so the kernel aborted.

Fix — a root sleep hook tears the mounts down before sleep and restarts them after: `/usr/lib/systemd/system-sleep/50-rclone-synology` (on `pre`: lazy-unmount the mountpoints, `systemctl --user stop` the units, SIGKILL any leftover `rclone mount` procs; on `post`: restart them). See `notes/synology-rclone-mount.md`. Suggest switching the desktop sleep action to suspend-then-hibernate (above) so a stalled hibernate still falls back to a low-power state.

## Diagnostics

Kernel PM debug messages are enabled persistently via `/etc/tmpfiles.d/pm-debug.conf`:
```
w /sys/power/pm_debug_messages - - - - 1
```

To capture which tasks refuse to freeze, hibernate and then immediately read the ring buffer (the kernel dumps the offending task names/stacks itself):
```bash
sudo dmesg -T | grep -iE -A30 'refusing to freeze'
```
