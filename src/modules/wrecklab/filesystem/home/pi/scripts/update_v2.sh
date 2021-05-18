#!/bin/bash

cd $HOME/klipper

TAG=$(git describe --tags --abbrev=0)
echo $TAG

git fetch --tags
TAG_NEW=$(git describe --tags --abbrev=0)
echo $TAG_NEW

if [ "$TAG" != "$TAG_NEW" ]
then
  git checkout "$TAG_NEW"
fi

# assume klipper config options have not changed
/usr/bin/make

# confirm jumper
read -p "Install the BOOT jumper and continue (Y/n)" jummper
jumper=${jumper:-y}

if [ $jumper != "y" ]
then
  exit
fi

sudo service klipper stop

# reset the board
echo "18" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio18/direction
echo "1" > /sys/class/gpio/gpio18/value

# flash the board
/usr/bin/make serialflash FLASH_DEVICE=/dev/ttyAMA0

# clear the reset
echo "0" > /sys/class/gpio/gpio18/value

# confirm no jumper
read -p "Remove the BOOT jumper and press ENTER" jumper

sudo service klipper start
