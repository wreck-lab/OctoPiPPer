#!/bin/bash
# This script installs Moonraker on a Raspberry Pi machine running
# Raspbian/Raspberry Pi OS based distributions.

KLIPPER_PYTHON_DIR="${HOME}/klippy-env"
KLIPPER_SOURCE_DIR="${HOME}/klipper"
SYSTEMDDIR="/etc/systemd/system"


install_packages()
{
    # Packages for python cffi
    PKGLIST="python-virtualenv virtualenv python-dev libffi-dev build-essential"
    # kconfig requirements
    PKGLIST="${PKGLIST} libncurses-dev"
    # hub-ctrl
    PKGLIST="${PKGLIST} libusb-dev"
    # AVR chip installation and building
    PKGLIST="${PKGLIST} avrdude gcc-avr binutils-avr avr-libc"
    # ARM chip installation and building
    PKGLIST="${PKGLIST} stm32flash dfu-util libnewlib-arm-none-eabi"
    PKGLIST="${PKGLIST} gcc-arm-none-eabi binutils-arm-none-eabi libusb-1.0"
	# Packages for Moonraker
    PKGLIST="${PKGLIST} python3-virtualenv python3-dev nginx libopenjp2-7 python3-libgpiod"



    # Update system package info
    report_status "Running apt-get update..."
    sudo apt-get update

    # Install desired packages
    report_status "Installing packages..."
    sudo apt-get install --yes ${PKGLIST}
}

create_klipper_venv()
{
    report_status "Updating Klippy python virtual environment..."

    # Create virtualenv if it doesn't already exist
    [ ! -d ${KLIPPER_PYTHON_DIR} ] && virtualenv ${KLIPPER_PYTHON_DIR}

    # Install/update dependencies
    ${KLIPPER_PYTHON_DIR}/bin/pip install -r ${KLIPPER_SOURCE_DIR}/scripts/klippy-requirements.txt
}

install_klipper_script()
{
    report_status "Installing Klipper system start script..."
    sudo cp "${KLIPPER_SOURCE_DIR}/scripts/klipper-start.sh" /etc/init.d/klipper
    sudo update-rc.d klipper defaults
}

# Step 4: Install startup script config
install_klipper_config()
{
    KLIPPER_DEFAULTS_FILE=/etc/default/klipper
    [ -f $KLIPPER_DEFAULTS_FILE ] && return

    report_status "Installing system start configuration..."
    sudo /bin/sh -c "cat > $KLIPPER_DEFAULTS_FILE" <<EOF
# Configuration for /etc/init.d/klipper

KLIPPY_USER=$USER

KLIPPY_EXEC=${KLIPPER_PYTHON_DIR}/bin/python

KLIPPY_ARGS="${KLIPPER_SOURCE_DIR}/klippy/klippy.py ${HOME}/klipper_config/printer.cfg -l /tmp/klippy.log -a /tmp/klippy_uds"

EOF
}

# Helper functions
report_status()
{
    echo -e "\n\n###### $1"
}

verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script must not run as root"
        exit -1
    fi
}

# Force script to exit if an error occurs
set -e

# Run installation steps defined above
verify_ready
install_packages
report_status "Installing Klipper..."
create_klipper_venv
install_klipper_script
install_klipper_config
#report_status "Installing Moonraker..."
#create_moonraker_venv
#install_moonraker_script
report_status "Install Complete!"
