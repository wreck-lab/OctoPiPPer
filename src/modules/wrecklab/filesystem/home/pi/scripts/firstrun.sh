#!/bin/bash

echo -n "Searching for firstrun... "

# check conditions for execution on stratup
if [[ -n "$(find /boot -name 'firstrun*' | head -1)" ]]; then
  echo "OK"

  # run the update script with no user prompt, and get the result
  ./update_v2.sh -a
  RES=$?

  echo -n "Updating process successful... "
  if [ "$RES" = "0" ]; then
    echo "YES"
    echo -n "Clearing firstrun... "
    /usr/bin/rm -f /boot/firstrun*
    echo "OK"

  else
    echo "NO"

  fi

else
  echo "NO"

fi
