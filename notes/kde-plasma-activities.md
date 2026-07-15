# KDE Plasma Activities

Activities are like separate virtual "workspaces" with their own set of running apps,
wallpaper, and (optionally) which apps/documents are associated with them — distinct
from virtual desktops, which just move windows around.

## Current activities (this machine)

Check with `kactivities-cli --list-activities`:

```
[CURRENT] a4de19d7-7c6a-4986-b61f-5e83a242611b Default ()
[RUNNING] 633c758f-6453-4f30-8824-c306ab3f675c Private (activities)
```

## Keyboard shortcuts

From `~/.config/kglobalshortcutsrc`. Two separate components define activity shortcuts:

### `[ActivityManager]` component ("Activity Manager")

Direct jump to a specific named activity:

| Shortcut     | Action                       |
|--------------|------------------------------|
| Meta+Ctrl+1  | Switch to activity "Default" |
| Meta+Ctrl+2  | Switch to activity "Private" |

These are per-activity bindings — a new entry gets added automatically each time you
create an activity, so this list grows over time.

### `[plasmashell]` component ("Plasma Workspace" in System Settings)

General activity navigation, not tied to a specific activity:

| Shortcut                  | Action                            |
|---------------------------|------------------------------------|
| Meta+Q                    | Show Activity Switcher (manage activities) |
| Meta+A or Meta+Tab        | Walk through activities (next)     |
| Meta+Shift+A or Meta+Shift+Tab | Walk through activities (reverse) |
| Meta+Ctrl+Right           | Switch to Next Activity            |
| Meta+Ctrl+Left            | Switch to Previous Activity        |

### Heads up: shortcut conflict

`Meta+Ctrl+Right` / `Meta+Ctrl+Left` are bound **both** to activity switching
(above) **and** to `kwin`'s "Switch One Desktop to the Right/Left" (virtual desktop
switching). Whichever one actually fires may depend on component load order — worth
rebinding one of them in System Settings > Shortcuts if it's ambiguous in practice.

## Where to manage activities

System Settings > Workspace Behavior > Activities — create/delete/rename activities
and set per-activity wallpaper here. Shortcuts themselves live under
System Settings > Shortcuts, under the "Activity Manager" and "Plasma Workspace"
components.

## Same Chrome profile signed in per-activity

Goal: use the same Google account/profile in Chrome, but have it open as a
separate window instance per activity (e.g. a "Private" activity gets its own
Chrome window, distinct from the "Default" activity's Chrome window), so KWin
window rules can bind windows to specific activities.

Approach: a custom `.desktop` launcher per activity, each pointing Chrome at
its own `--user-data-dir` and giving it a distinct `--class` so KWin can
target it by window class in window rules (System Settings > Window Management
> Window Rules — match on "Window class", set "Activities" to the desired
activity).

Created `~/.local/share/applications/chrome-activity-private.desktop` for the
"Private" activity:

```
Exec=google-chrome --user-data-dir=/home/spark/.config/google-chrome-activity-private --class=ChromeActivityPrivate %U
StartupWMClass=ChromeActivityPrivate
```

Gotchas hit along the way:

- The first draft of the Exec line had a stray literal `"class="` string fused
  onto the `--user-data-dir` value instead of a separate `--class=` flag —
  `desktop-file-validate` didn't catch it; `gio launch` surfaced it as
  "Syntax error in command ... coming from ...desktop".
- `%h` is **not** a valid `.desktop` Exec field code (the spec only defines
  `%f %F %u %U %d %D %n %N %i %c %k %v %m`) — it does not expand to `$HOME`.
  Desktop file Exec lines don't do shell/env-var expansion at all, so the
  home directory has to be spelled out as a literal absolute path
  (`/home/spark/...`), not `~` or `$HOME` or `%h`.
- Verified with `desktop-file-validate <file>` (syntax-level check only —
  it did NOT catch the `"class="` bug above, so also test with `gio launch
  <file>` and check `pgrep -af google-chrome` for the actual `--user-data-dir`
  and `--class` the process came up with).

### Pinning per-activity to the taskbar

Once the launcher works, pin it so it only shows up in the Task Manager while
in that activity:

1. Launch the app (e.g. via the `.desktop` launcher) so it has a running
   taskbar icon.
2. Right-click the taskbar icon > **Pin to Task Manager**.
3. Right-click the now-pinned icon again and pick the specific **Activity**
   it should be associated with.

Repeat per Chrome instance/activity (each with its own `.desktop` launcher and
`--class`) so each pinned icon only appears in its own activity's taskbar,
even though they're all "Chrome."

Next step (not done yet): create the matching launcher(s) for other
activities (e.g. `chrome-activity-default.desktop` with its own
`--user-data-dir`/`--class`), pin + assign each to its activity as above, then
optionally add KWin Window Rules to bind each `ChromeActivity*` window class
to its activity for stricter enforcement.

## Run a script automatically when an activity is switched to

kactivitymanagerd supports per-activity hook scripts on disk — no KWin
scripting or DBus-listener daemon needed. Drop an **executable** script in:

```
~/.local/share/kactivitymanagerd/activities/<activity-uuid>/activated/
```

Any script there runs when that activity becomes the current one. (There's
also a `deactivated/` counterpart for when you switch away from it.)

Find an activity's UUID with `kactivities-cli --list-activities` or
`qdbus6 org.kde.ActivityManager /ActivityManager/Activities CurrentActivity`.

### Example: auto "Show Desktop" when switching to Private

`~/.local/share/kactivitymanagerd/activities/633c758f-6453-4f30-8824-c306ab3f675c/activated/show_desktop.sh`:

```bash
#!/bin/bash
# Trigger the "Show Desktop" global shortcut
if command -v qdbus6 &> /dev/null; then
    qdbus6 org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"
else
    qdbus org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"
fi
```

Then `chmod +x` it. Confirmed working: switching to the Private activity
(`qdbus6 org.kde.ActivityManager /ActivityManager/Activities SetCurrentActivity
<uuid>`, or the Meta+Ctrl+2 shortcut) minimizes/hides all windows.

### Gotchas hit along the way

- **The script must be executable.** kactivitymanagerd execs it directly —
  without `chmod +x` it silently never runs.
- **`invokeShortcut` takes the shortcut name as ONE argument** — it has two
  overloads, `invokeShortcut(name)` and `invokeShortcut(name, context)`. If
  the string `"Show Desktop"` isn't properly quoted when the qdbus command
  gets built, the shell splits it into two words and qdbus silently calls
  the 2-arg overload as `invokeShortcut("Show", "Desktop")` — no error, exit
  code 0, but no shortcut named "Show" exists, so nothing happens. Always
  keep it quoted as a single argument: `invokeShortcut "Show Desktop"`.
- **Don't build scripts with `echo """..."""`.** Bash treats `"""` as an
  empty-quoted-string glued to the start of a new quote — any quotes typed
  *inside* that block get consumed as shell quoting, not written literally
  to the file. That's exactly how the `"Show Desktop"` quotes above got
  silently stripped on the first attempt. Use a quoted heredoc instead —
  `cat <<'EOF' > file` ... `EOF` — which passes the body through completely
  literally (no quote handling, no `$VAR`/backtick expansion) so nested
  quotes and special characters can't get mangled.
- Test empirically, not just with `desktop-file-validate`-style static
  checks: run the exact qdbus invocation by hand first to confirm it does
  the intended thing, then trigger it for real via `SetCurrentActivity` and
  watch for the actual effect.

### Suppressing the Show Desktop animation

The Show Desktop transition plays a KWin compositor effect, same as any
other minimize/maximize animation. It's distracting when it fires
automatically from the `activated/` hook above, so it's worth suppressing
just for that automated call — without turning the animation off globally
(it should still play if triggered manually, e.g. Meta+D, or when leaving
Private).

**Don't assume which effect it is — check.** My first guess was `squash`
(KWin's "Squash windows when they are minimized" effect, `EnabledByDefault`,
category `minimize`) since its description sounds like a Show Desktop match.
It's wrong: Show Desktop and per-window minimize are handled by two
*different* effects. Verified by polling KWin's DBus `activeEffects`
property at high frequency (every ~30ms) across a real Show Desktop trigger
and watching which effect ID actually appears active — `squash` never showed
up; `windowaperture` did (`EnabledByDefault`, category **`show-desktop`**,
description "Move windows into screen corners" — this is the actual one).
Toggling `squash` on/off had zero visible effect, which is exactly why this
was worth verifying empirically rather than trusting the plausible-sounding
name/description.

KWin exposes a DBus API (`org.kde.KWin` at path `/Effects`) to load/unload
effects **at runtime**, with no config file writes and no `kwin --replace`/
logout needed:

```bash
qdbus6 org.kde.KWin /Effects listOfEffects      # all effect IDs KWin knows about
qdbus6 org.kde.KWin /Effects loadedEffects      # currently loaded
qdbus6 org.kde.KWin /Effects activeEffects      # currently *animating* right now
qdbus6 org.kde.KWin /Effects isEffectLoaded <id>
qdbus6 org.kde.KWin /Effects unloadEffect <id>
qdbus6 org.kde.KWin /Effects loadEffect <id>
```

Final `activated/show_desktop.sh` — unload the effect immediately before
triggering Show Desktop, then reload it ~0.3s later so it's back for the
next manual trigger:

```bash
#!/bin/bash
QDBUS=qdbus6
command -v "$QDBUS" &> /dev/null || QDBUS=qdbus

"$QDBUS" org.kde.KWin /Effects unloadEffect windowaperture
"$QDBUS" org.kde.kglobalaccel /component/kwin invokeShortcut "Show Desktop"
sleep 0.3
"$QDBUS" org.kde.KWin /Effects loadEffect windowaperture
```

Confirmed working both by polling `activeEffects` (never shows
`windowaperture` during the switch) and visually (desktop appears instantly,
no animation).
