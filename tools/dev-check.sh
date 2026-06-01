#!/usr/bin/env bash
set -euo pipefail

bash -n bin/virt-mic-paw install.sh uninstall.sh tools/dev-check.sh tools/publish-github.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck bin/virt-mic-paw install.sh uninstall.sh tools/publish-github.sh completions/virt-mic-paw.bash
else
  echo "shellcheck not installed; skipped"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

make install DESTDIR="$tmpdir/root" PREFIX=/usr >/dev/null
service_file="$tmpdir/root/usr/share/systemd/user/virt-mic-paw.service"
grep -Fxq 'ExecStart=/usr/bin/virt-mic-paw start' "$service_file"
grep -Fxq 'ExecStop=/usr/bin/virt-mic-paw stop' "$service_file"
if grep -Fq '@BINDIR@' "$service_file"; then
  echo "service template placeholder was not rendered" >&2
  exit 1
fi

echo "checks ok"
