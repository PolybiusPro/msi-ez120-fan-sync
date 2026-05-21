# MSI EZ120 Fan Sync

Linux utility that sends a HID feature report to the MSI EZ120 fan controller (`0db0:1f1e`) so fan speeds stay in sync. A systemd oneshot unit runs it at boot with retries until the device appears.

## Requirements

- Linux with `hidraw` support
- `gcc` (to build from source)
- `systemd` (for the install script and service unit)
- Root or `sudo` to install

## Build

```bash
make
./msi-ez120-sync
```

## Install

From the repository root:

```bash
./install.sh
```

Options:

- `--prefix PATH` — install prefix (default: `/usr/local`)
- `-h`, `--help` — usage

The script compiles `src/ez120-sync.c`, installs `msi-ez120-sync` to `$(prefix)/bin`, installs `systemd/msi-ez120-sync.service`, enables it at boot, and starts it.

Check status:

```bash
systemctl status msi-ez120-sync.service
```

## Layout

```
.
├── src/ez120-sync.c          # HID sync tool source
├── systemd/msi-ez120-sync.service
├── install.sh                # build, install, enable service
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

## License

MIT — see [LICENSE](LICENSE).
