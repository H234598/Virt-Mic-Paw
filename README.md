# Virt-Mic-Paw

**Virt-Mic-Paw** baut auf Fedora/PipeWire ein virtuelles Eingabegerät, das zwei Audiosignale zusammenfasst:

1. dein echtes Mikrofon
2. das, was gerade über die Standard-Audioausgabe abgespielt wird

Das Ergebnis erscheint in Programmen als ein einzelnes Mikrofon, z. B. als:

```text
virtmicpaw
Virt-Mic-Paw-Mixed-Microphone
```

Damit kannst du in Programmen wie Browser, Discord, OBS, Audacity, Teams oder Jitsi gleichzeitig deine Stimme und Systemaudio als eine gemeinsame Eingabe verwenden.

## Kurzbild

```text
Mikrofon ───────────────┐
                        ├──> Virt-Mic-Paw Mix-Bus ──> virtmicpaw
Standardausgabe.monitor ┘
```

Intern nutzt Virt-Mic-Paw die PulseAudio-kompatiblen Module, die auf Fedora auch unter PipeWire funktionieren:

- `module-null-sink`
- `module-loopback`
- `module-remap-source`

## Voraussetzungen

Fedora mit PipeWire/PulseAudio-Kompatibilität. Auf aktuellen Fedora-Installationen ist das normalerweise bereits der Fall.

Empfohlene Pakete:

```bash
sudo dnf install pulseaudio-utils pipewire-pulseaudio pavucontrol
```

`pavucontrol` ist nicht zwingend nötig, aber sehr praktisch zum Kontrollieren und Balancieren der Streams.

## Installation für den aktuellen Nutzer

```bash
git clone https://github.com/H234598/Virt-Mic-Paw.git
cd Virt-Mic-Paw
./install.sh --enable
```

Ohne automatischen Start:

```bash
./install.sh --no-enable
```

Danach manuell starten:

```bash
virt-mic-paw start
```

Status anzeigen:

```bash
virt-mic-paw status
```

Stoppen:

```bash
virt-mic-paw stop
```

## systemd-User-Service

Aktivieren und sofort starten:

```bash
systemctl --user enable --now virt-mic-paw.service
```

Neu starten, z. B. nach Wechsel von Lautsprecher auf Bluetooth:

```bash
systemctl --user restart virt-mic-paw.service
```

Deaktivieren:

```bash
systemctl --user disable --now virt-mic-paw.service
```

## Geräte anzeigen

```bash
virt-mic-paw list
```

Damit findest du die Namen deiner echten Mikrofone, Ausgaben und Monitore.

## Bestimmtes Mikrofon oder bestimmte Ausgabe verwenden

Automatisch:

```bash
virt-mic-paw start
```

Explizit:

```bash
virt-mic-paw start \
  --mic alsa_input.usb-DEIN_MIKROFON.mono-fallback \
  --sink alsa_output.pci-0000_00_1f.3.analog-stereo
```

Oder direkt mit Monitor:

```bash
virt-mic-paw start \
  --mic alsa_input.usb-DEIN_MIKROFON.mono-fallback \
  --monitor alsa_output.pci-0000_00_1f.3.analog-stereo.monitor
```

## Konfiguration

Eine Beispielkonfiguration wird bei der Installation angelegt:

```text
~/.config/virt-mic-paw/config.env
```

Neu anlegen, falls sie fehlt:

```bash
virt-mic-paw config
```

Beispiel:

```bash
VMP_MIC_SOURCE="alsa_input.usb-Example_Microphone.mono-fallback"
VMP_SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
VMP_LATENCY_MSEC="20"
VMP_SET_DEFAULT_SOURCE="1"
```

## Lautstärke balancieren

Starte:

```bash
pavucontrol
```

Dann bei laufendem Virt-Mic-Paw in den Reitern **Playback/Wiedergabe** und **Recording/Aufnahme** nach den Loopback-Streams schauen. Dort kannst du Mikrofon und Systemaudio getrennt regeln.

## Troubleshooting

Diagnose:

```bash
virt-mic-paw diag
```

Wenn es knistert oder Aussetzer gibt:

```bash
virt-mic-paw restart --latency 50
```

Wenn nach dem Wechsel auf Bluetooth nichts mehr ankommt:

```bash
systemctl --user restart virt-mic-paw.service
```

Wenn das Programm das Gerät nicht sieht:

```bash
virt-mic-paw stop
virt-mic-paw start
```

Danach das Zielprogramm neu öffnen. Manche Apps lesen Eingabegeräte nur beim Start ein.

## Deinstallation

```bash
./uninstall.sh
```

Die Konfiguration unter `~/.config/virt-mic-paw` bleibt erhalten.

## Systemweite Installation

Für Paketbau oder manuelle systemweite Installation:

```bash
sudo make install PREFIX=/usr
systemctl --user daemon-reload
systemctl --user enable --now virt-mic-paw.service
```

Entfernen:

```bash
sudo make uninstall PREFIX=/usr
systemctl --user daemon-reload
```

## RPM-Bau

Die Datei `packaging/virt-mic-paw.spec` ist vorbereitet.

Grob:

```bash
git archive --format=tar.gz --prefix=virt-mic-paw-0.1.0/ -o virt-mic-paw-0.1.0.tar.gz HEAD
mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS
cp virt-mic-paw-0.1.0.tar.gz ~/rpmbuild/SOURCES/
cp packaging/virt-mic-paw.spec ~/rpmbuild/SPECS/
rpmbuild -ba ~/rpmbuild/SPECS/virt-mic-paw.spec
```

## Hinweis gegen Echo

Wenn du Lautsprecher statt Kopfhörer nutzt, kann dein echtes Mikrofon den Lautsprecher physisch wieder aufnehmen. Das klingt dann schnell wie eine Höhle mit beleidigtem Drachen. Für Calls und Streaming sind Kopfhörer klar besser.

## Lizenz

AGPL-3.0-or-later.
