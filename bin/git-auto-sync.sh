#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
cd "$DOTFILES_DIR"

git add -A

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

DIFF=$(git diff --cached)
MSG=""

if [ -n "${QWEN_API_KEY:-}" ]; then
  MSG=$(curl -sS --max-time 20 https://inference.provocative.earth/v1/chat/completions \
    -H "Authorization: Bearer $QWEN_API_KEY" \
    -H "content-type: application/json" \
    -d "$(jq -n --arg diff "$DIFF" '{
      model: "qwen3.6-35b",
      max_tokens: 100,
      messages: [
        {role: "system", content: "You write git commit messages. Given a diff, output ONLY a single-line commit message (max 72 chars), imperative mood, no preamble, no quotes, no markdown, no trailing period."},
        {role: "user", content: $diff}
      ]
    }')" 2>/dev/null | jq -r '.choices[0].message.content // empty') || MSG=""
elif [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  MSG=$(curl -sS --max-time 20 https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$(jq -n --arg diff "$DIFF" '{
      model: "claude-haiku-4-5",
      max_tokens: 100,
      system: "You write git commit messages. Given a diff, output ONLY a single-line commit message (max 72 chars), imperative mood, no preamble, no quotes, no markdown, no trailing period.",
      messages: [{role: "user", content: $diff}]
    }')" 2>/dev/null | jq -r '.content[0].text // empty') || MSG=""
fi

if [ -z "$MSG" ]; then
  MSG="auto-sync: $(date +%Y-%m-%d)"
fi

git commit -m "$MSG"

if ! git pull --rebase; then
  echo "git pull --rebase failed (conflict?) -- aborting rebase; commit stays local, unpushed." >&2
  git rebase --abort 2>/dev/null || true
  exit 1
fi

git push
