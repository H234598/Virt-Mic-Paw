# Security and privacy notes

Virt-Mic-Paw does not record, save or transmit audio by itself.

It creates a virtual audio input device. Any application that is allowed to use that input can receive the mixed audio stream while Virt-Mic-Paw is running.

## Be aware

- If the virtual microphone is selected in a meeting app, the other participants can hear both your microphone and selected system audio.
- If `VMP_SET_DEFAULT_SOURCE=1`, Virt-Mic-Paw sets itself as the default input device.
- Applications may remember previous audio-device choices.

## Stop immediately

```bash
virt-mic-paw stop
```

or, if installed as user service:

```bash
systemctl --user stop virt-mic-paw.service
```

## Inspect

```bash
virt-mic-paw status
pavucontrol
```

## Local state

Runtime module IDs are stored in a user-owned private state directory. If
`XDG_RUNTIME_DIR` is unavailable, Virt-Mic-Paw uses a UID-specific directory
below `/tmp` instead of a shared global path.

Config and runtime state paths are rejected when they are symlinks, because the
config file is sourced by the shell and state files control module cleanup.
