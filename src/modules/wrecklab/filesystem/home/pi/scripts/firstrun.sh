#!/bin/bash

LOG=/tmp/init.log

FORCE=false

log_date() {
  while IFS= read -r line; do
    echo "$(date) $line"
  done
}

# parse arguments
while getopts f o; do
  case $o in
    (f) FORCE=true;;
  esac
done

echo -n "Searching for firstrun... "
su -c "touch $LOG" pi

# check conditions for execution on stratup
if [[ -n "$(find /boot -name 'firstrun*' | head -1)" || "$FORCE" = "true" ]]; then
  echo "OK"

  # run the update script as pi, no user prompt (-r), no board reset (-r) and get the result
  su -c "source /home/pi/scripts/update_v2.sh -a -r" pi
  RES=$?

  echo -n "Updating process successful... "
  if [ "$RES" = "0" ]; then
    echo "YES"
    echo -n "Clearing firstrun... "
    /usr/bin/rm -f /boot/firstrun* | log_date >> $LOG 2>&1
    echo "OK" | log_date >> $LOG 2>&1

  else
    echo "NO" | log_date >> $LOG 2>&1

  fi

else
  echo "NO" | log_date >> $LOG 2>&1

fi
