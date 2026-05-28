# MSI EZ120 Fan Sync

Linux utility that sends HID feature reports to the MSI EZ120 fan controller (`0db0:1f1e`) so fan speeds and fan lighting are synced to the motherboard. A udev rule starts a oneshot systemd unit when the device appears.

## Clone

```bash
git clone https://github.com/PolybiusPro/msi-ez120-fan-sync.git
cd msi-ez120-fan-sync
```

## Requirements

- `gcc` (to build from source)
- `systemd` (for the install script and service unit)

## Build

```bash
make
./build/msi-ez120-sync
```

## Install

From the repository root:

```bash
./install.sh
```

Options:

- `--prefix PATH` — install prefix (default: `/usr/local`)
- `-h`, `--help` — usage

The script compiles `src/ez120-sync.c`, installs `msi-ez120-sync` to `$(prefix)/bin`, installs the systemd unit and udev rule, and runs sync once if the device is already connected.

Check status:

```bash
systemctl status msi-ez120-sync.service
```

## Layout

```
.
├── src/ez120-sync.c          # HID sync tool source
├── build/                    # compiled binary (gitignored)
├── systemd/msi-ez120-sync.service
├── udev/99-msi-ez120-sync.rules
├── install.sh                # build, install, udev trigger
├── uninstall.sh              # remove binary and disable service
├── Makefile
├── LICENSE
└── README.md
```

## Uninstall

```bash
./uninstall.sh
```

Options:

- `--prefix PATH` — must match the prefix used at install time (default: `/usr/local`)
- `-h`, `--help` — usage

> [!NOTE]
> If trying to set fan RGB in OpenRGB, you may encounter some issues with some of the LEDs refusing to light up due to the software not recognizing all of the LED nodes. As a workaround, you can set the colors in MysticLight on Windows and they should persist when booting into Linux. Just make sure that OpenRGB doesn't overwrite your motherboard config if you decide to continue using it.

## License

MIT — see [LICENSE](LICENSE).
