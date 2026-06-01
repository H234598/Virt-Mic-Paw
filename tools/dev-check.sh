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
test -x "$tmpdir/root/usr/bin/virt-mic-paw"
test -f "$tmpdir/root/usr/share/bash-completion/completions/virt-mic-paw"
test -f "$tmpdir/root/usr/share/doc/virt-mic-paw/README.md"
test -f "$tmpdir/root/usr/share/licenses/virt-mic-paw/LICENSE"

make uninstall DESTDIR="$tmpdir/root" PREFIX=/usr >/dev/null
if [[ -e "$tmpdir/root/usr/bin/virt-mic-paw" \
  || -e "$service_file" \
  || -e "$tmpdir/root/usr/share/bash-completion/completions/virt-mic-paw" \
  || -e "$tmpdir/root/usr/share/doc/virt-mic-paw" \
  || -e "$tmpdir/root/usr/share/licenses/virt-mic-paw" ]]; then
  echo "make uninstall left installed artifacts behind" >&2
  exit 1
fi

grep -Fxq 'BuildRequires:  make' packaging/virt-mic-paw.spec
grep -Fxq 'Requires:       pulseaudio-utils' packaging/virt-mic-paw.spec
grep -Fxq 'License:        AGPL-3.0-or-later' packaging/virt-mic-paw.spec

script_version="$(sed -n 's/^VERSION="\([^"]*\)"$/\1/p' bin/virt-mic-paw)"
spec_version="$(awk '$1 == "Version:" {print $2; exit}' packaging/virt-mic-paw.spec)"
if [[ -z "$script_version" || "$script_version" != "$spec_version" ]]; then
  echo "version mismatch between CLI and RPM spec" >&2
  exit 1
fi
grep -Fxq "## $script_version - 2026-06-01" CHANGELOG.md
grep -Fxq "virt-mic-paw $script_version" < <(bin/virt-mic-paw version)
grep -Fxq "virt-mic-paw $script_version" < <(bin/virt-mic-paw --version)

completion_commands="$(
  COMP_WORDS=(virt-mic-paw ver)
  COMP_CWORD=1
  # shellcheck source=/dev/null
  source completions/virt-mic-paw.bash
  _virt_mic_paw
  printf '%s\n' "${COMPREPLY[@]}"
)"
grep -Fxq 'version' <<<"$completion_commands"

completion_start_opts="$(
  COMP_WORDS=(virt-mic-paw start --)
  COMP_CWORD=2
  # shellcheck source=/dev/null
  source completions/virt-mic-paw.bash
  _virt_mic_paw
  printf '%s\n' "${COMPREPLY[@]}"
)"
grep -Fxq -- '--monitor' <<<"$completion_start_opts"
grep -Fxq -- '--no-default' <<<"$completion_start_opts"

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

if ./uninstall.sh --prefix >/dev/null 2>"$tmpdir/uninstall-prefix.err"; then
  echo "missing uninstall --prefix argument unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --prefix benötigt einen Wert.' "$tmpdir/uninstall-prefix.err"

config_home="$tmpdir/config-home"
mkdir -p "$config_home/virt-mic-paw"
cat >"$config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SINK="out"
VMP_MONITOR_SOURCE="out.monitor"
EOF
if XDG_CONFIG_HOME="$config_home" bin/virt-mic-paw start >/dev/null 2>"$tmpdir/config-exclusive.err"; then
  echo "config with sink and monitor unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --sink und --monitor dürfen nicht gemeinsam gesetzt werden.' "$tmpdir/config-exclusive.err"

cat >"$config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SET_DEFAULT_SOURCE="yes"
EOF
if XDG_CONFIG_HOME="$config_home" bin/virt-mic-paw start >/dev/null 2>"$tmpdir/config-default.err"; then
  echo "invalid VMP_SET_DEFAULT_SOURCE unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: VMP_SET_DEFAULT_SOURCE muss 0 oder 1 sein.' "$tmpdir/config-default.err"

fakebin="$tmpdir/fakebin"
mkdir -p "$fakebin"
cat >"$fakebin/pactl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log="${VMP_FAKE_PACTL_LOG:?}"
case "${1:-}" in
  get-default-sink)
    printf '%s\n' "test_sink"
    ;;
  get-default-source)
    printf '%s\n' "test_mic"
    ;;
  list)
    case "${2:-} ${3:-}" in
      "short sources")
        printf '1\ttest_mic\n2\ttest_sink.monitor\n'
        ;;
      "short modules")
        printf '\n'
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  load-module)
    printf 'load %s\n' "$2" >>"$log"
    case "$2" in
      module-null-sink) printf '101\n' ;;
      module-loopback)
        count_file="${VMP_FAKE_PACTL_COUNT:?}"
        count=0
        if [[ -f "$count_file" ]]; then
          count="$(cat "$count_file")"
        fi
        count=$((count + 1))
        printf '%s\n' "$count" >"$count_file"
        printf '%s\n' "$((101 + count))"
        ;;
      module-remap-source)
        exit 23
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  unload-module)
    printf 'unload %s\n' "$2" >>"$log"
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod +x "$fakebin/pactl"

fake_runtime="$tmpdir/runtime"
mkdir -p "$fake_runtime"
if PATH="$fakebin:$PATH" \
  XDG_RUNTIME_DIR="$fake_runtime" \
  VMP_FAKE_PACTL_LOG="$tmpdir/fake-pactl.log" \
  VMP_FAKE_PACTL_COUNT="$tmpdir/fake-pactl.count" \
  bin/virt-mic-paw start --no-default >/dev/null 2>"$tmpdir/start-rollback.err"; then
  echo "start with failing remap unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'WARN: Start fehlgeschlagen. Räume teilweise geladene Module auf.' "$tmpdir/start-rollback.err"
grep -Fxq 'unload 103' "$tmpdir/fake-pactl.log"
grep -Fxq 'unload 102' "$tmpdir/fake-pactl.log"
grep -Fxq 'unload 101' "$tmpdir/fake-pactl.log"
if [[ -e "$fake_runtime/virt-mic-paw/modules" ]]; then
  echo "state file remained after failed start rollback" >&2
  exit 1
fi

echo "checks ok"
