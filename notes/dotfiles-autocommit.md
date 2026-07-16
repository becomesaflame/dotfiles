# Dotfiles auto-commit

A systemd user timer that daily stages, commits, and pushes any changes in
`~/dotfiles`, using an LLM to write the commit message.

## How it works

`bin/git-auto-sync.sh`:

1. `git add -A` in `~/dotfiles`; exits quietly if nothing's staged.
2. Sends the staged diff to an LLM to get a one-line commit message. Tries,
   in order:
   - `QWEN_API_KEY` set → self-hosted vLLM server at
     `inference.provocative.earth` (OpenAI-compatible `/v1/chat/completions`
     API, model `qwen3.6-35b`)
   - `ANTHROPIC_API_KEY` set → Claude Haiku via the Anthropic Messages API
   - neither set, or the call fails/empty response → falls back to
     `auto-sync: <date>`
3. Commits with that message, `git pull --rebase`, then pushes. If the
   rebase hits a conflict, it aborts the rebase (`git rebase --abort`) and
   exits non-zero — the local commit is preserved but left unpushed rather
   than pushing a broken/conflicted state or leaving the repo stuck
   mid-rebase for the next run.

`dotfiles-autocommit.timer` (systemd user unit) fires it once a day
(`OnCalendar=daily`, `RandomizedDelaySec=10m`), with `Persistent=true` so a
missed run (machine asleep/off) catches up on next boot/wake.

## Files

| File | Purpose |
|---|---|
| `bin/git-auto-sync.sh` | the script itself, checked out as part of this repo |
| `systemd/dotfiles-autocommit.service` | systemd unit, symlink into `~/.config/systemd/user/` |
| `systemd/dotfiles-autocommit.timer` | schedule, symlink into `~/.config/systemd/user/` |
| `systemd/dotfiles-autocommit.env.example` | template — copy to `~/.config/dotfiles-autocommit.env`, fill in a real key, `chmod 600` |
| `~/.config/dotfiles-autocommit.env` | **not tracked** — holds the actual API key(s); kept outside the repo on purpose so a key can never end up committed/pushed |

See the README for setup steps on a new machine.

## Operating it

```sh
# Check the timer is enabled and see next scheduled run
systemctl --user list-timers dotfiles-autocommit.timer

# Trigger a run right now (goes through the same path as the timer, logs to journal)
systemctl --user start dotfiles-autocommit.service

# Or run it directly (same effect, output in your terminal instead of the journal)
~/dotfiles/bin/git-auto-sync.sh

# See what happened on the last run
journalctl --user -u dotfiles-autocommit.service -n 30 --no-pager
```

## Gotchas

- **The two LLM backends have different wire formats and the script has to
  match each one.** The Anthropic Messages API takes a top-level `system`
  field and returns text at `.content[0].text`. The Qwen/vLLM endpoint speaks
  the OpenAI `/v1/chat/completions` convention instead: no top-level
  `system` field (it has to be a `{"role": "system", ...}` entry inside
  `messages`), and the response text is at `.choices[0].message.content`,
  not `.content[...]`. Mixing these up doesn't error loudly — `jq`'s
  `// empty` fallback just silently produces an empty message, which looks
  like "the API call succeeded but did nothing" rather than a clear failure.
  If you ever add a third backend, check whether it's Anthropic-shaped or
  OpenAI-shaped before assuming either existing branch's parsing will work.
- **`EnvironmentFile=-%h/.config/dotfiles-autocommit.env`** — the leading
  `-` makes the file optional. Without it, a missing env file makes the
  *entire service* fail to start, not just skip the LLM call.
- **Never `echo`/log the key value anywhere in the script.** It ends up in
  the systemd journal in plaintext, readable by anything that can run
  `journalctl --user`, for as long as journal retention holds.
- **Secrets can't be piped through an interactive `read -s` prompt run via
  the `!` shell-passthrough in a Claude Code session** — no real interactive
  stdin gets forwarded, so `read` hits EOF immediately and silently no-ops.
  To hand-enter a secret into a file without it passing through an AI
  conversation's context, use a real separate terminal:
  `umask 077; cat > ~/.config/dotfiles-autocommit.env` then paste + Ctrl-D.
