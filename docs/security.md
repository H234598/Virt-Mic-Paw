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
