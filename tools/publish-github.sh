#!/usr/bin/env bash
set -euo pipefail

repo="${1:-}"
if [[ -z "$repo" ]]; then
  echo "Usage: $0 OWNER/REPO" >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git fehlt." >&2
  exit 1
fi

if [[ ! -d .git ]]; then
  git init
fi

if ! git config user.name >/dev/null; then
  git config user.name "Virt-Mic-Paw Builder"
fi
if ! git config user.email >/dev/null; then
  git config user.email "noreply@example.com"
fi

git add .
if ! git diff --cached --quiet; then
  git commit -m "Initial Virt-Mic-Paw project"
fi

git branch -M main

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "https://github.com/${repo}.git"
else
  git remote add origin "https://github.com/${repo}.git"
fi

# Optional: set repo description when gh is available.
if command -v gh >/dev/null 2>&1; then
  gh repo edit "$repo" --description "Fedora/PipeWire-Helfer: virtuelles Mikrofon aus echtem Mikrofon plus Systemaudio." || true
fi

git push -u origin main
