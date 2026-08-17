#!/bin/bash
# AIC8800D80 USB Mode Switch Installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE_SWITCH_CONFIG="$SCRIPT_DIR/etc/usb_modeswitch.d/1111:1111"
UDEV_RULE="$SCRIPT_DIR/etc/udev/rules.d/99-custom-usb-modeswitch.rules"

SYSTEM_MODE_SWITCH_DIR="/etc/usb_modeswitch.d"
SYSTEM_UDEV_DIR="/etc/udev/rules.d"

BANNER="$SCRIPT_DIR/assets/banner.txt"

[[ -f "$BANNER" ]] && cat "$BANNER"

if [[ $EUID -ne 0 ]]; then
    echo "This installer requires root privileges."
    exit 1
fi

if [[ -t 1 && "${TERM:-}" != "dumb" ]]; then
    RED='\033[31m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    CYAN='\033[36m'

    RESET='\033[0m'
    BOLD='\033[1m'
fi

step()        { printf "[%s] %-50s [${CYAN}RUNN${RESET}]\b\b\b\b\b\b" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"; }

success()     { printf "[${GREEN}DONE${RESET}]\n"; }
warning()     { printf "[${YELLOW}WARN${RESET}]\n"; }
error()       { printf "[${RED}FAIL${RESET}]\n"; }

info()        { printf "${CYAN}%s${RESET}\n" "$1"; }

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }

trap show_cursor EXIT
hide_cursor

step "Checking AIC8800D80 driver"

if dkms status 2>/dev/null | grep -qi 'aic8800'; then
    success
else
    warning

    echo
    info "The AIC8800D80 driver is not installed."
    info "It is required for the device after USB mode switching."
    echo
    info "The driver will be downloaded from:"
    echo "    https://github.com/shenmintao/aic8800d80.git"
    echo

    printf "Do you want to download and install the driver? [y/N]: "
    read -r answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then

        echo

        if ! command -v git >/dev/null 2>&1; then
            step "Installing git"

            if apt-get install -y git >/dev/null 2>&1; then
                success
            else
                error
                exit 1
            fi
        fi

        step "Cloning AIC8800D80 repository"

        AIC8800D80_REPO="$(mktemp -d -p /tmp aic8800d80-XXXXXX)"

        if git clone --depth 1 \
            https://github.com/shenmintao/aic8800d80.git \
            "$AIC8800D80_REPO" >/dev/null 2>&1; then
            success
        else
            error
            exit 1
        fi

        step "Installing AIC8800D80 driver"

        AIC8800D80_LOG="/var/log/aic8800d80-install.log"

        if ( cd "$AIC8800D80_REPO" && ./install.sh > "$AIC8800D80_LOG" 2>&1 ); then
            success
        else
            error
            echo
            info "See the installation log at $AIC8800D80_LOG"
            echo
        fi
        rm -rf "$AIC8800D80_REPO"
    else
        info "AIC8800D80 driver installation skipped."
        echo
    fi
fi

step "Checking usb_modeswitch configuration"

if [ -f "$MODE_SWITCH_CONFIG" ]; then
    success
else
    error
    echo
    echo "Missing: $MODE_SWITCH_CONFIG"
    exit 1
fi

step "Checking udev rule"

if [ -f "$UDEV_RULE" ]; then
    success
else
    error
    echo
    echo "Missing: $UDEV_RULE"
    exit 1
fi

step "Checking usb-modeswitch installation"

if dpkg -s usb-modeswitch >/dev/null 2>&1; then
    success
else
    warning
    step "Updating package database"

    if apt-get update >/dev/null 2>&1; then
        success
    else
        error
        exit 1
    fi

    step "Installing usb-modeswitch"

    if apt-get install -y usb-modeswitch >/dev/null 2>&1; then
        success
    else
        error
        exit 1
    fi
fi

step "Creating usb_modeswitch directory"

if mkdir -p "$SYSTEM_MODE_SWITCH_DIR"; then
    success
else
    error
    exit 1
fi

step "Creating udev rules directory"

if mkdir -p "$SYSTEM_UDEV_DIR"; then
    success
else
    error
    exit 1
fi

step "Creating usb_modeswitch configuration"

if cp "$MODE_SWITCH_CONFIG" "$SYSTEM_MODE_SWITCH_DIR/1111:1111"; then
    success
else
    error
    exit 1
fi

step "Creating udev rule"

if cp "$UDEV_RULE" "$SYSTEM_UDEV_DIR/99-custom-usb-modeswitch.rules"; then
    success
else
    error
    exit 1
fi

step "Reloading udev rules"

if udevadm control --reload-rules; then
    success
else
    error
    exit 1
fi

step "Triggering  udev"

if udevadm trigger; then
    success
else
    error
    exit 1
fi

echo
printf "${GREEN}${BOLD}Installation completed successfully.${RESET}\n"
echo

info "Installed files:"
echo "    $SYSTEM_MODE_SWITCH_DIR/1111:1111"
echo "    $SYSTEM_UDEV_DIR/99-custom-usb-modeswitch.rules"

echo
info "Unplug and reconnect the USB device."
echo
