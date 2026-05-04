# Remap Caps Lock to Ctrl on KDE Plasma 6 (Wayland)

`setxkbmap` won't work — it only affects XWayland apps, not native Wayland apps.

## Steps

```bash
kwriteconfig6 --file kxkbrc --group Layout --key Options "ctrl:nocaps"
kwriteconfig6 --file kxkbrc --group Layout --key ResetOldOptions true
kwriteconfig6 --file kxkbrc --group Layout --key Use true
```

Log out and back in.

## Why three keys?

- `Options=ctrl:nocaps` — the XKB option that makes Caps Lock act as Ctrl
- `ResetOldOptions=true` — tells KWin to clear any previously applied XKB options before applying the new ones; without this, the option may be silently ignored
- `Use=true` — tells KDE to actually use the custom layout settings from this file
