#!/bin/sh

# prerequisites

set -u

# check whether `local` is supported
has_local() {
    # clear path and run in the subshell
    (PATH="" local _has_local)
}

# alias `local` to `typeset` if unsupported
has_local 2>/dev/null || alias local=typeset

# variables

JIYU_INSTALL_VERSION="0.1.0"
JIYU_INSTALL_CONFIRM=yes
JIYU_INSTALL_QUIET=no

JIYU_NAME="jiyu"

JIYU_ROOT="${JIYU_INSTALL_ROOT:-https://install.jiyu.sh/static}"

# usage

version() {
    echo "$JIYU_NAME-install $JIYU_INSTALL_VERSION"
}

usage() {
    cat <<EOF
$(version)

The installer for $JIYU_NAME.

Usage: $JIYU_NAME-install [OPTIONS]

Options:
    -v, --verbose
        Enable verbose output.
    -q, --quiet
        Force output to be quiet.
    -y, --yes
        Disable confirmation prompts.
    -h, --help
        Print help and usage information.
    -V, --version
        Print installer version.
EOF
}

# main

main() {
    process_arguments "$@"

    enable_ansi_if_supported

    if [ "$JIYU_INSTALL_CONFIRM" = "no" ]; then
        info "skipping confirmation prompts"
    fi

    local target

    if ! target="$(get_target)"; then
        exit 1
    fi

    info "target is '$target'"
}

# implementation

process_arguments() {
    for argument in "$@"; do
        case "$argument" in
            --help)
                usage
                exit 0
            ;;
            --version)
                version
                exit 0
            ;;
            --quiet)
                JIYU_INSTALL_QUIET=yes
            ;;
            --yes)
                JIYU_INSTALL_CONFIRM=no
            ;;
            *)
                OPTIND=1

                if [ "${argument%%--*}" = "" ]; then
                    # long argument, do not interpret
                    continue
                fi

                while getopts :hqyV sub_argument "$argument"; do
                    case "$sub_argument" in
                        h)
                            usage
                            exit 0
                        ;;
                        V)
                            version
                            exit 0
                        ;;
                        q)
                            JIYU_INSTALL_QUIET=yes
                        ;;
                        y)
                            JIYU_INSTALL_CONFIRM=no
                        ;;
                        *)
                            # do nothing here
                        ;;
                    esac
                done
            ;;
        esac
    done
}

downloader() {
    local download_command

    if check_command curl; then
        download_command=curl
    elif check_command wget; then
        download_command=wget
    else
        download_command="curl or wget" # used in `need_command` error
    fi

    if [ "$1" = "--check" ]; then
        need_command "$download_command"
    fi
}

ensure() {
    if ! "$@"; then
        error "command '$*' failed"
        exit 1
    fi
}

ignore() {
    "$@"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

need_command() {
    if ! check_command "$1"; then
        error "$1 is needed (command not found)"
        exit 1
    fi
}

get_library() {
    if ldd --version 2>&1 | grep -q "musl"; then
        echo "musl"
    else
        echo "gnu"
    fi
}

get_platform() {
    need_command uname

    local platform="$(uname -s)"

    case "$platform" in
        Linux)
            echo "unknown-linux-$(get_library)"
        ;;
        Darwin)
            echo "apple-darwin"
        ;;
        *)
            error "unsupported platform '$platform'"
            exit 1
        ;;
    esac
}

get_architecture() {
    need_command uname

    local architecture="$(uname -m)"

    case "$architecture" in
        x86_64)
            echo "x86_64"
        ;;
        aarch64|arm64)
            echo "aarch64"
        ;;
        *)
            error "unsupported architecture '$architecture'"
            exit 1
        ;;
    esac
}

get_target() {
    local architecture

    if ! architecture="$(get_architecture)"; then
        exit 1
    fi

    local platform

    if ! platform="$(get_platform)"; then
        exit 1
    fi

    echo "$architecture-$platform"
}

ANSI_SUPPORTED=false

enable_ansi_if_supported() {
    if [ -t 2 ]; then
        case "${TERM-}" in
            xterm*|rxvt*|urxvt*|linux*|vt*)
                ANSI_SUPPORTED=true
            ;;
        esac
    fi
}

info() {
    if [ "$JIYU_INSTALL_QUIET" = "no" ]; then
        if $ANSI_SUPPORTED; then
            printf "\33[1;32minfo:\33[0m %s\n" "$1" >&2
        else
            printf "info: %s\n" "$1" >&2
        fi
    fi
}

warn() {
    if $ANSI_SUPPORTED; then
        printf "\33[1;33mwarn:\33[0m %s\n" "$1" >&2
    else
        printf "warn: %s\n" "$1" >&2
    fi
}

error() {
    if $ANSI_SUPPORTED; then
        printf "\33[1;31merror:\33[0m %s\n" "$1" >&2
    else
        printf "error: %s\n" "$1" >&2
    fi
}

# entrypoint

set +u

main "$@"
