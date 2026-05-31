# Troubleshooting

## The virtual microphone does not appear

Restart Virt-Mic-Paw and then restart the target application:

```bash
virt-mic-paw restart
```

Some programs only enumerate audio devices at startup.

## The system-audio part is silent

Your default output may have changed. Restart:

```bash
systemctl --user restart virt-mic-paw.service
```

or specify the sink directly:

```bash
virt-mic-paw start --sink NAME_FROM_VIRT_MIC_PAW_LIST
```

## Crackling or dropouts

Increase latency:

```bash
virt-mic-paw restart --latency 50
```

Bluetooth may need 100 ms.

## Echo or feedback

Use headphones. If you play audio through speakers, your real microphone can pick it up again physically.

## Full diagnosis

```bash
virt-mic-paw diag
```

Paste that output into an issue if you need help.
