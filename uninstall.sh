#!/bin/bash
# AIC8800D80 USB Mode Switch Uninstaller

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SYSTEM_MODE_SWITCH_CONFIG="/etc/usb_modeswitch.d/1111:1111"
SYSTEM_UDEV_RULE="/etc/udev/rules.d/99-custom-usb-modeswitch.rules"

BANNER="$SCRIPT_DIR/assets/banner.txt"

[[ -f "$BANNER" ]] && cat "$BANNER"

if [[ $EUID -ne 0 ]]; then
    echo "This uninstaller requires root privileges."
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

step "Checking usb_modeswitch configuration"

if [[ -f "$SYSTEM_MODE_SWITCH_CONFIG" ]]; then
    success
else
    warning
    info "Configuration is not installed."
fi

step "Checking udev rule"

if [[ -f "$SYSTEM_UDEV_RULE" ]]; then
    success
else
    warning
    info "udev rule is not installed."
fi

step "Removing usb_modeswitch configuration"

if [[ -f "$SYSTEM_MODE_SWITCH_CONFIG" ]]; then
    if rm -f "$SYSTEM_MODE_SWITCH_CONFIG"; then
        success
    else
        error
        exit 1
    fi
else
    warning
fi

step "Removing udev rule"

if [[ -f "$SYSTEM_UDEV_RULE" ]]; then
    if rm -f "$SYSTEM_UDEV_RULE"; then
        success
    else
        error
        exit 1
    fi
else
    warning
fi

step "Reloading udev rules"

if udevadm control --reload-rules; then
    success
else
    error
    exit 1
fi

step "Triggering udev"

if udevadm trigger; then
    success
else
    error
    exit 1
fi

echo
printf "${GREEN}${BOLD}Uninstallation completed successfully.${RESET}\n"
echo

info "Removed files:"
echo "    $SYSTEM_MODE_SWITCH_CONFIG"
echo "    $SYSTEM_UDEV_RULE"

echo
info "Unplug and reconnect the USB device."
echo
