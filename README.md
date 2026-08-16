
# AIC8800D80 ModeSwitch

A small Linux installer for switching AIC8800D80-based USB wireless
devices from their initial USB mode to their wireless mode.

## Problem

Some AIC8800D80 USB devices initially appear with the USB ID:

```text
1111:1111
````

Because the device is not yet presenting its wireless interface, the appropriate driver cannot bind to it.

This project installs the required `usb_modeswitch` configuration and udev rule to automatically switch the device to:

```text
a69c:8d81
```

The device can then be handled by the AIC8800D80 driver.

## What it does

The installer:

1. Checks the AIC8800D80 driver.
2. Optionally downloads and installs the AIC8800D80 driver.
3. Installs `usb-modeswitch` if necessary.
4. Installs the `1111:1111` mode-switch configuration.
5. Installs the custom udev rule.
6. Reloads the udev rules.
7. Triggers udev.

## Installation

Clone the repository:

```bash
git clone https://github.com/0xberka/aic8800d80-modeswitch.git
cd aic8800d80-modeswitch
```

Run the installer:

```bash
sudo ./install.sh
```

The installer will ask for confirmation before downloading the
AIC8800D80 driver from:

```text
https://github.com/shenmintao/aic8800d80.git
```

## Uninstallation

To remove the mode-switch configuration and udev rule:

```bash
sudo ./uninstall.sh
```

The uninstaller removes:

```text
/etc/usb_modeswitch.d/1111:1111
/etc/udev/rules.d/99-custom-usb-modeswitch.rules
```

It then reloads and triggers udev.

> The uninstaller does not currently remove the AIC8800D80 driver.

## License

See the repository license for details.
