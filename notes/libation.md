# Libation

## Folder formatting string:
`<first author[{L}, {T} {F} {M}]><if series->/<first series><-if series>/<series#>_<title>`

## Books location

Libation's "Books" location is set to `~/Synology/audiobooks/audiobooks`, which is the **rclone mount** (see `notes/synology-rclone-mount.md`). So downloaded books are written straight to the Synology over SFTP — they're cached locally (rclone `full` mode) but the canonical copy lives on the NAS, not on this machine.

## Gotchas

- **Colons in titles break phone transfers.** The `<title>` field often contains a `:` (e.g. `4_Lux: A Texas Reckoners Novel`). Android file managers refuse to move files into a folder whose name has a colon, so copying a book to a phone requires renaming the folder colon-free first. If this becomes a recurring annoyance, change the folder template to strip/replace colons.
- Large books can't be copied to a phone over MTP/USB (the write fails) — use KDE Connect over wifi.
