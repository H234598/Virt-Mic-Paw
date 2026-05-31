#!/usr/bin/env bash
set -euo pipefail

bash -n bin/virt-mic-paw install.sh uninstall.sh tools/publish-github.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck bin/virt-mic-paw install.sh uninstall.sh tools/publish-github.sh completions/virt-mic-paw.bash
else
  echo "shellcheck not installed; skipped"
fi

echo "checks ok"
