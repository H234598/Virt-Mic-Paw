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

if bin/virt-mic-paw start --mic >/dev/null 2>"$tmpdir/missing-arg.err"; then
  echo "missing --mic argument unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --mic benötigt einen Wert.' "$tmpdir/missing-arg.err"

if bin/virt-mic-paw start --sink out --monitor out.monitor >/dev/null 2>"$tmpdir/exclusive.err"; then
  echo "--sink with --monitor unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --sink und --monitor dürfen nicht gemeinsam gesetzt werden.' "$tmpdir/exclusive.err"

if bin/virt-mic-paw start --latency 0 >/dev/null 2>"$tmpdir/latency.err"; then
  echo "--latency 0 unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --latency muss mindestens 1 Millisekunde sein.' "$tmpdir/latency.err"

if ./install.sh --prefix >/dev/null 2>"$tmpdir/install-prefix.err"; then
  echo "missing install --prefix argument unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --prefix benötigt einen Wert.' "$tmpdir/install-prefix.err"

echo "checks ok"
