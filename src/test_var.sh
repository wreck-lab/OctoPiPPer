#!/bin/bash

if [ "$GUI" = "octoprint" ]; then
  sed -i 's/^.*\bBASE_IMAGE_ENLARGEROOT\b.*$/stefaninos_octoprint/' ./config
  sed -i 's/^.*\bMODULES\b.*$/stefaninos_modules/' ./config
else
  sed -i 's/^.*\bBASE_IMAGE_ENLARGEROOT\b.*$/export BASE_IMAGE_ENLARGEROOT=2000/' ./config
  sed -i 's/^.*\bMODULES\b.*$/export MODULES="base(network, raspicam, klipper, moonraker, mainsail, mjpgstreamer, disable-services(auto-hotspot, wrecklab), password-for-sudo)"/' ./config
fi

#stefaninos_octoprint
# export BASE_IMAGE_ENLARGEROOT=3000
# export MODULES="base(raspicam, network, klipper, disable-services(octopi, auto-hotspot, wrecklab), password-for-sudo)"
