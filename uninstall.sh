#!/usr/bin/env bash
# Uninstall msi-ez120-sync and disable the systemd unit.
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${PREFIX}/bin"
SYSTEMD_DIR="/etc/systemd/system"
UNIT_NAME="msi-ez120-sync.service"
UDEV_RULES="/etc/udev/rules.d/99-msi-ez120-sync.rules"
BINARY_NAME="msi-ez120-sync"

run_as_root() {
    if [[ "${EUID}" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "error: root privileges required (re-run as root or install sudo)" >&2
        exit 1
    fi
}

uninstall() {
    run_as_root systemctl disable --now "${UNIT_NAME}" 2>/dev/null || true
    run_as_root rm -f "${SYSTEMD_DIR}/${UNIT_NAME}"
    run_as_root rm -f "${UDEV_RULES}"
    run_as_root rm -f "${BINDIR}/${BINARY_NAME}"
    run_as_root systemctl daemon-reload
    if command -v udevadm >/dev/null 2>&1; then
        run_as_root udevadm control --reload-rules
    fi
    echo "Uninstalled ${BINARY_NAME}."
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Remove ${BINARY_NAME}, its systemd unit, and disable the service.

Options:
  --prefix PATH   Install prefix used at install time (default: /usr/local)
  -h, --help      Show this help

Environment:
  PREFIX          Same as --prefix

Examples:
  ./uninstall.sh
  sudo ./uninstall.sh --prefix /usr
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --prefix)
                PREFIX="$2"
                BINDIR="${PREFIX}/bin"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "error: unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    if ! command -v systemctl >/dev/null 2>&1; then
        echo "error: systemd (systemctl) is required" >&2
        exit 1
    fi

    uninstall
}

main "$@"
