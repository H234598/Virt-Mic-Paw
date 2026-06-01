#!/usr/bin/env bash
set -Eeuo pipefail

trap 'rc=$?; echo "dev-check failed at line $LINENO" >&2; exit "$rc"' ERR

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
grep -Fxq '  virt-mic-paw --version' < <(bin/virt-mic-paw help)

completion_commands="$(
  COMP_WORDS=(virt-mic-paw ver)
  COMP_CWORD=1
  # shellcheck source=/dev/null
  source completions/virt-mic-paw.bash
  _virt_mic_paw
  printf '%s\n' "${COMPREPLY[@]}"
)"
grep -Fxq 'version' <<<"$completion_commands"

completion_global_opts="$(
  COMP_WORDS=(virt-mic-paw --)
  COMP_CWORD=1
  # shellcheck source=/dev/null
  source completions/virt-mic-paw.bash
  _virt_mic_paw
  printf '%s\n' "${COMPREPLY[@]}"
)"
grep -Fxq -- '--version' <<<"$completion_global_opts"

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

no_pactl_path="$tmpdir/no-pactl-path"
mkdir -p "$no_pactl_path"
ln -s "$(command -v bash)" "$no_pactl_path/bash"
ln -s "$(command -v dirname)" "$no_pactl_path/dirname"
if PATH="$no_pactl_path" ./install.sh --enable --prefix "$tmpdir/no-pactl-prefix" \
  >/dev/null 2>"$tmpdir/install-enable-no-pactl.err"; then
  echo "install --enable without pactl unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: pactl nicht gefunden; --enable kann den Dienst nicht zuverlässig starten.' \
  "$tmpdir/install-enable-no-pactl.err"

for cmd in awk cat chmod env install mkdir pwd; do
  ln -s "$(command -v "$cmd")" "$no_pactl_path/$cmd"
done
cat >"$no_pactl_path/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$no_pactl_path/systemctl"

no_enable_home="$tmpdir/no-enable-home"
mkdir -p "$no_enable_home/config" "$no_enable_home/data"
if ! PATH="$no_pactl_path" \
  HOME="$no_enable_home/home" \
  XDG_CONFIG_HOME="$no_enable_home/config" \
  XDG_DATA_HOME="$no_enable_home/data" \
  ./install.sh --no-enable --prefix "$tmpdir/no-enable-prefix" \
  >"$tmpdir/install-no-enable-no-pactl.out" 2>"$tmpdir/install-no-enable-no-pactl.err"; then
  echo "install --no-enable without pactl unexpectedly failed" >&2
  cat "$tmpdir/install-no-enable-no-pactl.err" >&2
  exit 1
fi
grep -Fxq 'WARN: pactl nicht gefunden. Auf Fedora: sudo dnf install pulseaudio-utils' \
  "$tmpdir/install-no-enable-no-pactl.err"
grep -Fxq 'Virt-Mic-Paw installiert. Starte mit: virt-mic-paw start' \
  "$tmpdir/install-no-enable-no-pactl.out"
test -x "$tmpdir/no-enable-prefix/bin/virt-mic-paw"
test -f "$no_enable_home/config/systemd/user/virt-mic-paw.service"
test -f "$no_enable_home/data/bash-completion/completions/virt-mic-paw"

enable_fail_path="$tmpdir/enable-fail-path"
mkdir -p "$enable_fail_path"
for cmd in awk cat chmod dirname env install mkdir pwd; do
  ln -s "$(command -v "$cmd")" "$enable_fail_path/$cmd"
done
ln -s "$(command -v bash)" "$enable_fail_path/bash"
cat >"$enable_fail_path/pactl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$enable_fail_path/systemctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == "--user daemon-reload" ]]; then
  exit 0
fi
exit 42
EOF
chmod +x "$enable_fail_path/pactl" "$enable_fail_path/systemctl"

enable_fail_home="$tmpdir/enable-fail-home"
mkdir -p "$enable_fail_home/config" "$enable_fail_home/data"
if PATH="$enable_fail_path" \
  HOME="$enable_fail_home/home" \
  XDG_CONFIG_HOME="$enable_fail_home/config" \
  XDG_DATA_HOME="$enable_fail_home/data" \
  ./install.sh --enable --prefix "$tmpdir/enable-fail-prefix" \
  >"$tmpdir/install-enable-systemctl.out" 2>"$tmpdir/install-enable-systemctl.err"; then
  echo "install --enable with failing systemctl unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: virt-mic-paw.service konnte nicht aktiviert oder gestartet werden.' \
  "$tmpdir/install-enable-systemctl.err"
grep -Fxq 'Prüfe: systemctl --user status virt-mic-paw.service' \
  "$tmpdir/install-enable-systemctl.err"

if ./uninstall.sh --prefix >/dev/null 2>"$tmpdir/uninstall-prefix.err"; then
  echo "missing uninstall --prefix argument unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --prefix benötigt einen Wert.' "$tmpdir/uninstall-prefix.err"

if tools/publish-github.sh 'bad repo/name' >/dev/null 2>"$tmpdir/publish-repo.err"; then
  echo "publish accepted invalid repo argument" >&2
  exit 1
fi
grep -Fxq 'repo must be in OWNER/REPO format.' "$tmpdir/publish-repo.err"

config_home="$tmpdir/config-home"
mkdir -p "$config_home/virt-mic-paw"
chmod 0700 "$config_home/virt-mic-paw"
cat >"$config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SINK="out"
VMP_MONITOR_SOURCE="out.monitor"
EOF
chmod 0600 "$config_home/virt-mic-paw/config.env"
if XDG_CONFIG_HOME="$config_home" bin/virt-mic-paw start >/dev/null 2>"$tmpdir/config-exclusive.err"; then
  echo "config with sink and monitor unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: --sink und --monitor dürfen nicht gemeinsam gesetzt werden.' "$tmpdir/config-exclusive.err"

cat >"$config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SET_DEFAULT_SOURCE="yes"
EOF
chmod 0600 "$config_home/virt-mic-paw/config.env"
if XDG_CONFIG_HOME="$config_home" bin/virt-mic-paw start >/dev/null 2>"$tmpdir/config-default.err"; then
  echo "invalid VMP_SET_DEFAULT_SOURCE unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: VMP_SET_DEFAULT_SOURCE muss 0 oder 1 sein.' "$tmpdir/config-default.err"

insecure_config_home="$tmpdir/insecure-config-home"
mkdir -p "$insecure_config_home/virt-mic-paw"
chmod 0700 "$insecure_config_home/virt-mic-paw"
cat >"$insecure_config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SET_DEFAULT_SOURCE="1"
EOF
chmod 0666 "$insecure_config_home/virt-mic-paw/config.env"
if XDG_CONFIG_HOME="$insecure_config_home" bin/virt-mic-paw version \
  >/dev/null 2>"$tmpdir/config-insecure.err"; then
  echo "world-writable config unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq "ERROR: Konfiguration ist gruppen- oder welt-schreibbar: $insecure_config_home/virt-mic-paw/config.env" \
  "$tmpdir/config-insecure.err"

insecure_config_dir_home="$tmpdir/insecure-config-dir-home"
mkdir -p "$insecure_config_dir_home/virt-mic-paw"
cat >"$insecure_config_dir_home/virt-mic-paw/config.env" <<'EOF'
VMP_SET_DEFAULT_SOURCE="1"
EOF
chmod 0600 "$insecure_config_dir_home/virt-mic-paw/config.env"
chmod 0777 "$insecure_config_dir_home/virt-mic-paw"
if XDG_CONFIG_HOME="$insecure_config_dir_home" bin/virt-mic-paw version \
  >/dev/null 2>"$tmpdir/config-dir-insecure.err"; then
  echo "world-writable config directory unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq "ERROR: Config-Verzeichnis ist gruppen- oder welt-schreibbar: $insecure_config_dir_home/virt-mic-paw" \
  "$tmpdir/config-dir-insecure.err"

wrong_owner_config_home="$tmpdir/wrong-owner-config-home"
mkdir -p "$wrong_owner_config_home/virt-mic-paw"
chmod 0700 "$wrong_owner_config_home/virt-mic-paw"
cat >"$wrong_owner_config_home/virt-mic-paw/config.env" <<'EOF'
VMP_SET_DEFAULT_SOURCE="1"
EOF
chmod 0600 "$wrong_owner_config_home/virt-mic-paw/config.env"
wrong_owner_path="$tmpdir/wrong-owner-path"
mkdir -p "$wrong_owner_path"
cat >"$wrong_owner_path/stat" <<EOF
#!/usr/bin/env bash
if [[ "\$*" == "-c %u %a $wrong_owner_config_home/virt-mic-paw/config.env" ]]; then
  printf '%s\n' '0 600'
else
  exec /usr/bin/stat "\$@"
fi
EOF
cat >"$wrong_owner_path/id" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-u" ]]; then
  printf '%s\n' '1000'
else
  exec /usr/bin/id "$@"
fi
EOF
chmod +x "$wrong_owner_path/stat" "$wrong_owner_path/id"
if PATH="$wrong_owner_path:$PATH" XDG_CONFIG_HOME="$wrong_owner_config_home" \
  bin/virt-mic-paw version >/dev/null 2>"$tmpdir/config-wrong-owner.err"; then
  echo "wrong-owner config unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq "ERROR: Konfiguration gehört nicht dem aktuellen Nutzer: $wrong_owner_config_home/virt-mic-paw/config.env" \
  "$tmpdir/config-wrong-owner.err"

default_config_home="$tmpdir/default-config-home"
XDG_CONFIG_HOME="$default_config_home" bin/virt-mic-paw config >"$tmpdir/config-create.out"
grep -Fxq "Konfiguration erstellt: $default_config_home/virt-mic-paw/config.env" \
  "$tmpdir/config-create.out"
config_mode="$(stat -c '%a' "$default_config_home/virt-mic-paw/config.env")"
if [[ "$config_mode" != "600" ]]; then
  echo "default config mode was $config_mode, expected 600" >&2
  exit 1
fi

fakebin="$tmpdir/fakebin"
mkdir -p "$fakebin"
cat >"$fakebin/pactl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
log="${VMP_FAKE_PACTL_LOG:-}"
case "${1:-}" in
  get-default-sink)
    printf '%s\n' "test_sink"
    ;;
  get-default-source)
    printf '%s\n' "test_mic"
    ;;
  info)
    printf '%s\n' "Server Name: fake-pactl"
    ;;
  list)
    case "${2:-} ${3:-}" in
      "short sources")
        if [[ "${VMP_FAKE_PACTL_STATUS:-}" == "active" ]]; then
          printf '1\ttest_mic\n2\ttest_sink.monitor\n3\tvirtmicpaw\n'
        elif [[ "${VMP_FAKE_PACTL_STATUS:-}" == "module-only" ]]; then
          printf '1\ttest_mic\n2\ttest_sink.monitor\n'
        elif [[ "${VMP_FAKE_PACTL_STATUS:-}" == "source-substring" ]]; then
          printf '1\ttest_mic\n2\tnotvirtmicpaw\n'
        else
          printf '1\ttest_mic\n2\ttest_sink.monitor\n'
        fi
        ;;
      "short modules")
        if [[ "${VMP_FAKE_PACTL_STATUS:-}" == "active" || "${VMP_FAKE_PACTL_STATUS:-}" == "module-only" ]]; then
          printf '10\tmodule-null-sink\tapplication.name=virt-mic-paw\n'
        elif [[ "${VMP_FAKE_PACTL_STATUS:-}" == "module-substring" ]]; then
          printf '10\tmodule-null-sink\tapplication.name=notvirt-mic-paw\n'
        else
          printf '\n'
        fi
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  load-module)
    if [[ -z "$log" ]]; then
      exit 2
    fi
    printf 'load %s\n' "$2" >>"$log"
    case "$2" in
      module-null-sink)
        if [[ "${VMP_FAKE_PACTL_BAD_ID:-}" == "empty" ]]; then
          printf '\n'
        else
          printf '101\n'
        fi
        ;;
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
        if [[ "${VMP_FAKE_PACTL_REMAP:-}" == "ok" ]]; then
          printf '104\n'
        else
          exit 23
        fi
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  unload-module)
    if [[ -z "$log" ]]; then
      exit 2
    fi
    printf 'unload %s\n' "$2" >>"$log"
    ;;
  set-default-source)
    if [[ -z "$log" ]]; then
      exit 2
    fi
    printf 'default %s\n' "$2" >>"$log"
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod +x "$fakebin/pactl"

start_runtime="$tmpdir/start-runtime"
mkdir -p "$start_runtime"
PATH="$fakebin:$PATH" \
  XDG_RUNTIME_DIR="$start_runtime" \
  VMP_FAKE_PACTL_LOG="$tmpdir/start-ok-pactl.log" \
  VMP_FAKE_PACTL_COUNT="$tmpdir/start-ok-pactl.count" \
  VMP_FAKE_PACTL_REMAP=ok \
  bin/virt-mic-paw start >"$tmpdir/start-ok.out"
grep -Fxq 'Virt-Mic-Paw läuft.' "$tmpdir/start-ok.out"
grep -Fxq 'load module-null-sink' "$tmpdir/start-ok-pactl.log"
grep -Fxq 'load module-remap-source' "$tmpdir/start-ok-pactl.log"
grep -Fxq 'default virtmicpaw' "$tmpdir/start-ok-pactl.log"
grep -Fxq '101' "$start_runtime/virt-mic-paw/modules"
grep -Fxq '102' "$start_runtime/virt-mic-paw/modules"
grep -Fxq '103' "$start_runtime/virt-mic-paw/modules"
grep -Fxq '104' "$start_runtime/virt-mic-paw/modules"

bad_id_runtime="$tmpdir/bad-id-runtime"
mkdir -p "$bad_id_runtime"
if PATH="$fakebin:$PATH" \
  XDG_RUNTIME_DIR="$bad_id_runtime" \
  VMP_FAKE_PACTL_LOG="$tmpdir/bad-id-pactl.log" \
  VMP_FAKE_PACTL_BAD_ID=empty \
  bin/virt-mic-paw start >"$tmpdir/bad-id.out" 2>"$tmpdir/bad-id.err"; then
  echo "start with empty module id unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'ERROR: pactl load-module lieferte keine gültige Modul-ID für module-null-sink.' \
  "$tmpdir/bad-id.err"
grep -Fxq 'WARN: Start fehlgeschlagen. Räume teilweise geladene Module auf.' "$tmpdir/bad-id.err"
if [[ -s "$bad_id_runtime/virt-mic-paw/modules" ]]; then
  echo "state file contains an invalid module id" >&2
  cat "$bad_id_runtime/virt-mic-paw/modules" >&2
  exit 1
fi

bad_state_runtime="$tmpdir/bad-state-runtime"
mkdir -p "$bad_state_runtime/virt-mic-paw"
cat >"$bad_state_runtime/virt-mic-paw/modules" <<'EOF'
101
not-a-module-id
102
EOF
PATH="$fakebin:$PATH" \
  XDG_RUNTIME_DIR="$bad_state_runtime" \
  VMP_FAKE_PACTL_LOG="$tmpdir/bad-state-pactl.log" \
  bin/virt-mic-paw stop >"$tmpdir/bad-state.out" 2>"$tmpdir/bad-state.err"
grep -Fxq 'WARN: Ungültige Modul-ID in State-Datei übersprungen: not-a-module-id' \
  "$tmpdir/bad-state.err"
grep -Fxq 'unload 102' "$tmpdir/bad-state-pactl.log"
grep -Fxq 'unload 101' "$tmpdir/bad-state-pactl.log"
if grep -Fq 'not-a-module-id' "$tmpdir/bad-state-pactl.log"; then
  echo "stop passed an invalid state module id to pactl" >&2
  cat "$tmpdir/bad-state-pactl.log" >&2
  exit 1
fi
if [[ -e "$bad_state_runtime/virt-mic-paw/modules" ]]; then
  echo "state file remained after stop with invalid module id" >&2
  exit 1
fi

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

if PATH="$fakebin:$PATH" bin/virt-mic-paw status >"$tmpdir/status-inactive.out"; then
  echo "inactive status unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'Virtuelles Mikrofon nicht aktiv.' "$tmpdir/status-inactive.out"

if ! PATH="$fakebin:$PATH" VMP_FAKE_PACTL_STATUS=active \
  bin/virt-mic-paw status >"$tmpdir/status-active.out"; then
  echo "active status unexpectedly failed" >&2
  exit 1
fi
grep -Fq 'application.name=virt-mic-paw' "$tmpdir/status-active.out"
grep -Fq 'virtmicpaw' "$tmpdir/status-active.out"

if PATH="$fakebin:$PATH" VMP_FAKE_PACTL_STATUS=module-only \
  bin/virt-mic-paw status >"$tmpdir/status-module-only.out"; then
  echo "module-only status unexpectedly succeeded" >&2
  exit 1
fi
grep -Fq 'application.name=virt-mic-paw' "$tmpdir/status-module-only.out"
grep -Fxq 'Virtuelles Mikrofon nicht aktiv.' "$tmpdir/status-module-only.out"

if PATH="$fakebin:$PATH" VMP_FAKE_PACTL_STATUS=source-substring \
  bin/virt-mic-paw status >"$tmpdir/status-source-substring.out"; then
  echo "substring source status unexpectedly succeeded" >&2
  exit 1
fi
grep -Fxq 'Virtuelles Mikrofon nicht aktiv.' "$tmpdir/status-source-substring.out"

PATH="$fakebin:$PATH" \
  XDG_RUNTIME_DIR="$tmpdir/stop-runtime" \
  VMP_FAKE_PACTL_STATUS=module-substring \
  VMP_FAKE_PACTL_LOG="$tmpdir/stop-module-substring.log" \
  bin/virt-mic-paw stop >/dev/null
if [[ -s "$tmpdir/stop-module-substring.log" ]]; then
  echo "stop unloaded a non-matching application.name module" >&2
  cat "$tmpdir/stop-module-substring.log" >&2
  exit 1
fi

PATH="$fakebin:$PATH" VMP_FAKE_PACTL_STATUS=active \
  bin/virt-mic-paw diag >"$tmpdir/diag-active.out"
grep -Fxq '== Module ==' "$tmpdir/diag-active.out"
grep -Fq 'application.name=virt-mic-paw' "$tmpdir/diag-active.out"
grep -Fxq 'Server Name: fake-pactl' "$tmpdir/diag-active.out"

echo "checks ok"
