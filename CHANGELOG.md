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

## 0.1.0 - 2026-06-01

- Initial release.
- Adds virtual mixed microphone from physical microphone plus default output monitor.
- Adds user installer, systemd user service, bash completion, diagnostics and RPM spec skeleton.
