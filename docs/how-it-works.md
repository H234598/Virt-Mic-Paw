# How Virt-Mic-Paw works

Virt-Mic-Paw uses the PulseAudio compatibility layer provided by PipeWire on modern Fedora systems.

The setup has three pieces:

```text
physical microphone ───┐
                       ├──> null sink: virtmicpaw_bus ──> monitor source
output monitor ────────┘
```

Then the monitor source of that bus is exposed as a friendlier virtual source:

```text
virtmicpaw_bus.monitor ──remap-source──> virtmicpaw
```

## Modules

### module-null-sink

Creates a virtual sink called `virtmicpaw_bus`. Audio can be sent into this sink. Every sink has a monitor source, so everything arriving in the sink can be recorded through `virtmicpaw_bus.monitor`.

### module-loopback

Virt-Mic-Paw creates two loopbacks:

1. real microphone -> `virtmicpaw_bus`
2. selected output monitor -> `virtmicpaw_bus`

### module-remap-source

Creates the nicer input device `virtmicpaw` from `virtmicpaw_bus.monitor`.

## Why this works well on Fedora

Fedora usually runs PipeWire plus `pipewire-pulse`. That means PulseAudio client tools such as `pactl` remain usable, but the actual graph is handled by PipeWire.

## Latency

The default latency is 20 ms. If audio crackles or drops out, increase it:

```bash
virt-mic-paw restart --latency 50
```

Bluetooth devices may need higher values.
