# Changelog

## Unreleased

- Render the systemd user service from the selected install prefix instead of hard-coding `~/.local/bin`.
- Add an install smoke test to the development checks for the generated systemd service.
- Correct the RPM license metadata to `AGPL-3.0-or-later`.
- Update the ShellCheck workflow to `actions/checkout@v6`.

## 0.1.0 - 2026-06-01

- Initial release.
- Adds virtual mixed microphone from physical microphone plus default output monitor.
- Adds user installer, systemd user service, bash completion, diagnostics and RPM spec skeleton.
