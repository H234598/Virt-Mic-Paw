#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BINDIR="$PREFIX/bin"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
DOC_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/doc/virt-mic-paw"

systemctl --user disable --now virt-mic-paw.service >/dev/null 2>&1 || true

if [[ -x "$BINDIR/virt-mic-paw" ]]; then
  "$BINDIR/virt-mic-paw" stop >/dev/null 2>&1 || true
fi

rm -f "$BINDIR/virt-mic-paw"
rm -f "$SYSTEMD_USER_DIR/virt-mic-paw.service"
rm -f "$COMPLETION_DIR/virt-mic-paw"
rm -rf "$DOC_DIR"

systemctl --user daemon-reload >/dev/null 2>&1 || true

echo "Virt-Mic-Paw deinstalliert. Konfiguration unter ~/.config/virt-mic-paw bleibt erhalten."
