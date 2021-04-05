#!/bin/bash

KLIPPER_PRINTHAT_VER="v1"

install_phat_v1()
{
    echo "--- Configuring printHAT v1"
	cp /home/pi/klipper_config/phatv1_defconfig /home/pi/klipper/.config
	cd /home/pi/klipper
    make
    cp /home/pi/klipper_config/config/generic-wrecklab-printhat-v1-cartesian.cfg printer.cfg
}

install_phat_v2()
{
    echo "--- Configuring printHAT v2"
	cp /home/pi/klipper_config/phatv2_defconfig /home/pi/klipper/.config
	cd /home/pi/klipper
    make
    cp /home/pi/klipper_config/config/generic-wrecklab-printhat-v2-cartesian.cfg printer.cfg
}

# Force script to exit if an error occurs
set -e

# files in home
if [ "$KLIPPER_PRINTHAT_VER" == "v1" ]
then
	install_phat_v1
elif [ "$KLIPPER_PRINTHAT_VER" == "v2" ] 
then
	install_phat_v2
fi
