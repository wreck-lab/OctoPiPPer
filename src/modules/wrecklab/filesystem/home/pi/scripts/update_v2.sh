#!/bin/bash

# check conditions for execution
if [ -f "/boot/firstrun" ]; then
 echo "Found firstrun file. Updating..."
else
 if [ -f "/boot/firstrun.txt" ]; then
  echo "Found firstrun.txt file. Updating..."
 else
  if [ ! -z "$1" -a "$1" == "f" ]; then
   echo "Force update. Updating..."
  else
   echo "No firstrun file or force update flag."
   exit
  fi
 fi
fi

cd $HOME/klipper
REMOTE="https://github.com/wreck-lab/klipper.git"

TAG=$(git describe --tags --abbrev=0)
echo $TAG

# get remote tags
TAG_NEW=$(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags $REMOTE '*.*.*' | tail --lines=1 | cut --delimiter='/' --fields=3)
echo $TAG_NEW

if [ -z "$TAG" -o -z "$TAG_NEW" -o  "$TAG" == "$TAG_NEW" ]
then
  echo  "Nothing to update. Exit."
  exit
fi

git pull
git checkout "$TAG_NEW" -b "$TAG_NEW"

# assume klipper config options have not changed
/usr/bin/make

## flash board
# confirm jumper
read -p "Install the BOOT jumper and continue (Y/n)" jummper
jumper=${jumper:-y}

if [ $jumper != "y" ]
then
 exit
fi

# stop klipper
sudo service klipper stop

# reset board
echo 4 > /sys/class/gpio/export
sleep 0.1
echo out > /sys/class/gpio/gpio4/direction
echo 1 > /sys/class/gpio/gpio4/value
sleep 0.5
echo 0 > /sys/class/gpio/gpio4/value
sleep 0.5
echo 1 > /sys/class/gpio/gpio4/value

# flash
/usr/bin/make serialflash FLASH_DEVICE=/dev/ttyAMA0

echo 4 > /sys/class/gpio/unexport

read -p "Remove the BOOT jumper and press ENTER" jumper

# start klipper
sudo service klipper start

echo "Done."


