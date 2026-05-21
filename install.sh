#!/usr/bin/env bash
# Install msi-ez120-sync and enable it at boot via systemd.
set -euo pipefail

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${PREFIX}/bin"
SYSTEMD_DIR="/etc/systemd/system"
UNIT_NAME="msi-ez120-sync.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_C="${SCRIPT_DIR}/src/ez120-sync.c"
UNIT_SOURCE="${SCRIPT_DIR}/systemd/${UNIT_NAME}"
UDEV_RULES_NAME="99-msi-ez120-sync.rules"
UDEV_RULES_SOURCE="${SCRIPT_DIR}/udev/${UDEV_RULES_NAME}"
UDEV_RULES_DIR="/etc/udev/rules.d"
BINARY_NAME="msi-ez120-sync"
BUILD_DIR="${SCRIPT_DIR}/build"
BUILD_BINARY="${BUILD_DIR}/${BINARY_NAME}"

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

build_binary() {
    local out="$1"
    if [[ ! -f "${SOURCE_C}" ]]; then
        echo "error: ${SOURCE_C} not found" >&2
        exit 1
    fi
    if ! command -v gcc >/dev/null 2>&1; then
        echo "error: gcc is required to build ${BINARY_NAME}" >&2
        exit 1
    fi
    echo "Building ${BINARY_NAME}..."
    gcc -O2 -Wall -Wextra -o "${out}" "${SOURCE_C}"
}

install_files() {
    local binary_to_install

    if [[ -f "${SOURCE_C}" ]]; then
        mkdir -p "${BUILD_DIR}"
        build_binary "${BUILD_BINARY}"
        binary_to_install="${BUILD_BINARY}"
    elif [[ -f "${BUILD_BINARY}" ]]; then
        binary_to_install="${BUILD_BINARY}"
    else
        echo "error: need src/ez120-sync.c or ${BUILD_BINARY}" >&2
        exit 1
    fi

    run_as_root install -d "${BINDIR}"
    run_as_root install -m 755 "${binary_to_install}" "${BINDIR}/${BINARY_NAME}"

    if [[ ! -f "${UNIT_SOURCE}" ]]; then
        echo "error: ${UNIT_SOURCE} not found" >&2
        exit 1
    fi
    if [[ ! -f "${UDEV_RULES_SOURCE}" ]]; then
        echo "error: ${UDEV_RULES_SOURCE} not found" >&2
        exit 1
    fi

    run_as_root install -m 644 "${UNIT_SOURCE}" "${SYSTEMD_DIR}/${UNIT_NAME}"
    run_as_root install -m 644 "${UDEV_RULES_SOURCE}" "${UDEV_RULES_DIR}/${UDEV_RULES_NAME}"

    # Patch binary path in unit if PREFIX is not /usr/local
    if [[ "${PREFIX}" != "/usr/local" ]]; then
        run_as_root sed -i "s|/usr/local/bin/${BINARY_NAME}|${BINDIR}/${BINARY_NAME}|g" \
            "${SYSTEMD_DIR}/${UNIT_NAME}"
    fi

    # Drop legacy boot enable (was WantedBy=multi-user + udev-settle + 30s retry)
    run_as_root systemctl disable --now "${UNIT_NAME}" 2>/dev/null || true

    run_as_root systemctl daemon-reload
    run_as_root udevadm control --reload-rules
    run_as_root udevadm trigger --action=add --subsystem-match=usb \
        --attr-match=idVendor=0db0 --attr-match=idProduct=1f1e 2>/dev/null || true
    run_as_root systemctl start "${UNIT_NAME}" 2>/dev/null || true
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install ${BINARY_NAME} and enable it at boot (systemd).

Options:
  --prefix PATH   Install prefix (default: /usr/local)
  -h, --help      Show this help

Environment:
  PREFIX          Same as --prefix

Examples:
  ./install.sh
  sudo ./install.sh --prefix /usr
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

    install_files
    echo "Installed ${BINDIR}/${BINARY_NAME}"
    echo "Udev rule installed — sync runs when device 0db0:1f1e appears (not at every boot)."
    echo "Check status: systemctl status ${UNIT_NAME}"
}

main "$@"
