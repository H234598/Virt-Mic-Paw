#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
ENABLE="1"

usage() {
  cat <<'EOF'
Install Virt-Mic-Paw for the current user.

Usage:
  ./install.sh [--enable|--no-enable] [--prefix PATH]

Default prefix:
  ~/.local
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable) ENABLE="1"; shift ;;
    --no-enable) ENABLE="0"; shift ;;
    --prefix) PREFIX="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$PREFIX" ]]; then
  echo "Prefix must not be empty." >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINDIR="$PREFIX/bin"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SYSTEMD_USER_SERVICE="$SYSTEMD_USER_DIR/virt-mic-paw.service"
COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
DOC_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/doc/virt-mic-paw"

command -v pactl >/dev/null 2>&1 || {
  echo "WARN: pactl nicht gefunden. Auf Fedora: sudo dnf install pulseaudio-utils" >&2
}

install -Dm755 "$SCRIPT_DIR/bin/virt-mic-paw" "$BINDIR/virt-mic-paw"
install -d "$SYSTEMD_USER_DIR"
awk -v bindir="$BINDIR" '{gsub(/@BINDIR@/, bindir)} {print}' \
  "$SCRIPT_DIR/systemd/user/virt-mic-paw.service.in" >"$SYSTEMD_USER_SERVICE"
chmod 0644 "$SYSTEMD_USER_SERVICE"
install -Dm644 "$SCRIPT_DIR/completions/virt-mic-paw.bash" "$COMPLETION_DIR/virt-mic-paw"
install -Dm644 "$SCRIPT_DIR/README.md" "$DOC_DIR/README.md"
install -Dm644 "$SCRIPT_DIR/docs/how-it-works.md" "$DOC_DIR/how-it-works.md"
install -Dm644 "$SCRIPT_DIR/docs/troubleshooting.md" "$DOC_DIR/troubleshooting.md"
install -Dm644 "$SCRIPT_DIR/docs/security.md" "$DOC_DIR/security.md"

"$BINDIR/virt-mic-paw" config

systemctl --user daemon-reload >/dev/null 2>&1 || true

if [[ "$ENABLE" == "1" ]]; then
  systemctl --user enable --now virt-mic-paw.service
  echo "Virt-Mic-Paw installiert und gestartet."
else
  echo "Virt-Mic-Paw installiert. Starte mit: virt-mic-paw start"
fi

case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) echo "Hinweis: $BINDIR ist nicht in PATH. Öffne eine neue Shell oder ergänze PATH." ;;
esac
