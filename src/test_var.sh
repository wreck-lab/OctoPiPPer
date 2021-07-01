#!/bin/bash

if [ "$GUI" = "octoprint" ]; then
  sed -i 's/^.*\bBASE_IMAGE_ENLARGEROOT\b.*$/export BASE_IMAGE_ENLARGEROOT=3000/' ./config
  sed -i 's/^.*\bMODULES\b.*$/export MODULES="base(raspicam, network, klipper, disable-services(octopi, auto-hotspot, wrecklab), password-for-sudo)"/' ./config
else
  sed -i 's/^.*\bBASE_IMAGE_ENLARGEROOT\b.*$/export BASE_IMAGE_ENLARGEROOT=2000/' ./config
  sed -i 's/^.*\bMODULES\b.*$/export MODULES="base(network, raspicam, klipper, moonraker, mainsail, mjpgstreamer, disable-services(auto-hotspot, wrecklab), password-for-sudo)"/' ./config
  for filename in modules/klipper/filesystem/home/pi/klipper_config/config/*.cfg; do
    printf "\n" >> "$filename"
    sed -i -e '$a[include mainsail.cfg]' "$filename"
  done
fi
