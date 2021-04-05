#!/bin/bash

KLIPPER_PRINTHAT_VER="v1"

install_phat_v1()
{
    echo "--- Configuring printHAT v1"
	cd /home/pi/klipper
	cp phatv1_defconfig .config
    make
    cd ..
    cp klipper/config/generic-wrecklab-printhat-v1-cartesian.cfg printer.cfg
}

install_phat_v2()
{
    echo "--- Configuring printHAT v2"
	cd /home/pi/klipper
	cp phatv2_defconfig .config
    make
    cd ..
    cp klipper/config/generic-wrecklab-printhat-v2-cartesian.cfg printer.cfg
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
