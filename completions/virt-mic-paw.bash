# bash completion for virt-mic-paw

_virt_mic_paw() {
  local cur prev commands opts_start opts_global
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="start stop restart status list config diag version help"
  opts_start="--mic --sink --monitor --latency --no-default --help"
  opts_global="--help --version"

  case "$prev" in
    --mic|--monitor)
      if command -v pactl >/dev/null 2>&1; then
        mapfile -t COMPREPLY < <(compgen -W "$(pactl list short sources 2>/dev/null | awk '{print $2}')" -- "$cur")
      fi
      return 0
      ;;
    --sink)
      if command -v pactl >/dev/null 2>&1; then
        mapfile -t COMPREPLY < <(compgen -W "$(pactl list short sinks 2>/dev/null | awk '{print $2}')" -- "$cur")
      fi
      return 0
      ;;
    --latency)
      mapfile -t COMPREPLY < <(compgen -W "20 30 50 100" -- "$cur")
      return 0
      ;;
  esac

  if [[ $COMP_CWORD -eq 1 ]]; then
    mapfile -t COMPREPLY < <(compgen -W "$commands $opts_global" -- "$cur")
    return 0
  fi

  case "${COMP_WORDS[1]}" in
    start|restart)
      mapfile -t COMPREPLY < <(compgen -W "$opts_start" -- "$cur")
      ;;
    *)
      mapfile -t COMPREPLY < <(compgen -W "$opts_global" -- "$cur")
      ;;
  esac
}

complete -F _virt_mic_paw virt-mic-paw
