# Changelog

## Unreleased

- Render the systemd user service from the selected install prefix instead of hard-coding `~/.local/bin`.
- Add an install smoke test to the development checks for the generated systemd service.
- Correct the RPM license metadata to `AGPL-3.0-or-later`.
- Update the ShellCheck workflow to `actions/checkout@v6`.
- Harden `start` and `restart` option parsing for missing values, invalid latency and mutually exclusive sink/monitor selection.
- Harden `install.sh --prefix` option parsing for missing values.
- Validate conflicting sink/monitor configuration and invalid `VMP_SET_DEFAULT_SOURCE` values.
- Roll back partially loaded PulseAudio modules when startup fails midway.
- Run CI checks through the public `make check` target.
- Declare `make` as an RPM build dependency and check key spec metadata in development checks.
- Add `uninstall.sh --prefix` support matching the installer.
- Add a `make uninstall` smoke test for installed files, service, completion, docs and license paths.
- Add `virt-mic-paw version` and `--version` output.
- Check version consistency across CLI, RPM spec and changelog.
- Add functional smoke tests for bash completion commands and start options.
- Make `install.sh --enable` fail early when `pactl` is unavailable.
- Test that `install.sh --no-enable` still works without `pactl`.
- Add fake-`pactl` smoke tests for active and inactive `status` behavior.
- Make `status` succeed only when the virtual source is present, not merely when stale modules exist.
- Validate `tools/publish-github.sh` repository arguments before writing Git remotes.
- Report a clear installer error when `systemctl --user enable --now` fails.
- Include loaded PulseAudio modules in `diag` output.

## 0.1.0 - 2026-06-01

- Initial release.
- Adds virtual mixed microphone from physical microphone plus default output monitor.
- Adds user installer, systemd user service, bash completion, diagnostics and RPM spec skeleton.
