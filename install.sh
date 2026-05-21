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
    local tmp_binary
    tmp_binary="$(mktemp)"
    trap 'rm -f "${tmp_binary}"' RETURN

    if [[ -f "${SOURCE_C}" ]]; then
        build_binary "${tmp_binary}"
    elif [[ -f "${SCRIPT_DIR}/msi-ez120-sync" ]]; then
        cp "${SCRIPT_DIR}/msi-ez120-sync" "${tmp_binary}"
    else
        echo "error: need src/ez120-sync.c or a prebuilt msi-ez120-sync binary" >&2
        exit 1
    fi

    run_as_root install -d "${BINDIR}"
    run_as_root install -m 755 "${tmp_binary}" "${BINDIR}/${BINARY_NAME}"

    if [[ ! -f "${UNIT_SOURCE}" ]]; then
        echo "error: ${UNIT_SOURCE} not found" >&2
        exit 1
    fi
    run_as_root install -m 644 "${UNIT_SOURCE}" "${SYSTEMD_DIR}/${UNIT_NAME}"

    # Patch ExecStart path if PREFIX is not /usr/local
    if [[ "${PREFIX}" != "/usr/local" ]]; then
        run_as_root sed -i "s|/usr/local/bin/${BINARY_NAME}|${BINDIR}/${BINARY_NAME}|g" \
            "${SYSTEMD_DIR}/${UNIT_NAME}"
    fi

    run_as_root systemctl daemon-reload
    run_as_root systemctl enable "${UNIT_NAME}"
    run_as_root systemctl restart "${UNIT_NAME}" || true
}

uninstall() {
    run_as_root systemctl disable --now "${UNIT_NAME}" 2>/dev/null || true
    run_as_root rm -f "${SYSTEMD_DIR}/${UNIT_NAME}"
    run_as_root rm -f "${BINDIR}/${BINARY_NAME}"
    run_as_root systemctl daemon-reload
    echo "Uninstalled ${BINARY_NAME}."
}

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install ${BINARY_NAME} and enable it at boot (systemd).

Options:
  --prefix PATH   Install prefix (default: /usr/local)
  --uninstall     Remove binary, unit, and disable service
  -h, --help      Show this help

Environment:
  PREFIX          Same as --prefix

Examples:
  ./install.sh
  sudo ./install.sh --prefix /usr
  ./install.sh --uninstall
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
            --uninstall)
                uninstall
                exit 0
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
    echo "Enabled ${UNIT_NAME} (runs at boot)."
    echo "Check status: systemctl status ${UNIT_NAME}"
}

main "$@"
