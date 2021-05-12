#!/bin/bash

# Force script to exit if an error occurs
set -e

echo $1

#KLIPPER_PHAT_VERSION=$1
KLIPPER_PHAT_VERSION=v2

echo "--- Configuring printHAT ${KLIPPER_PHAT_VERSION}..."
cp /home/pi/klipper_config/phat${KLIPPER_PHAT_VERSION}_defconfig /home/pi/klipper/.config
cp /home/pi/klipper_config/config/generic-wrecklab-printhat-${KLIPPER_PHAT_VERSION}-cartesian.cfg /home/pi/klipper_config/printer.cfg
ln -s /home/pi/klipper_config/printer.cfg /home/pi/printer.cfg

echo "--- Compiling Klipper firmware..."
cd /home/pi/klipper
make
