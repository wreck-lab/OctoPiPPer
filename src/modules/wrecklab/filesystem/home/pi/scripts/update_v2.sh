#!/bin/bash
# optional first argument: 'wrecklab' or 'klipper'
$KLIPPER_UPDATE = $1

cd $HOME/klipper

# get the flavor currently installed
if [[ $(git config --get remote.origin.url) == *"KevinOConnor"* ]]
then
  $KLIPPER_INSTALL = 'klipper'
else
  $KLIPPER_INSTALL = 'wrecklab'
fi

# update local
#git pull https://github.com/KevinOConnor/klipper.git
git pull https://github.com/wreck-lab/klipper.git

# assume klipper config options have not changed
make

## flash board
# (remember to put jumper before and remove it after)
echo "18" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio18/direction
echo "1" > /sys/class/gpio/gpio18/value

/usr/bin/make serialflash FLASH_DEVICE=/dev/ttyAMA0

echo "0" > /sys/class/gpio/gpio18/value
