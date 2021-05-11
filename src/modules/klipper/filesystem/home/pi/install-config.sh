#!/bin/bash

# Force script to exit if an error occurs
set -e

echo "--- Configuring printHAT ${phat_ver} ..."
cp /home/pi/klipper_config/phat${phat_ver}_defconfig /home/pi/klipper/.config
cp /home/pi/klipper_config/config/generic-wrecklab-printhat-${phat_ver}-cartesian.cfg /home/pi/klipper_config/printer.cfg
ln -s /home/pi/klipper_config/printer.cfg /home/pi/printer.cfg

echo "--- Compiling Klipper firmware..."
cd /home/pi/klipper
make
