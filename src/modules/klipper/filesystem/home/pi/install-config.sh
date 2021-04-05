#!/bin/bash

KLIPPER_PRINTHAT_VER="v1"

# Force script to exit if an error occurs
set -e

echo "--- Configuring printHAT ${KLIPPER_PRINTHAT_VER} ..."
cp /home/pi/klipper_extra/phat${KLIPPER_PRINTHAT_VER}_defconfig /home/pi/klipper/.config
cp /home/pi/klipper_extra/config/generic-wrecklab-printhat-${KLIPPER_PRINTHAT_VER}-cartesian.cfg /home/pi/printer.cfg

echo "--- Compiling Klipper firmware..."
cd /home/pi/klipper
make
