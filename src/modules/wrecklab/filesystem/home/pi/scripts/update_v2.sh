#!/bin/bash

PROGNAME=$0
FORCE=false
BRANCH="master"
LOCAL=$HOME/klipper
REMOTE="https://github.com/wreck-lab/klipper.git"
LOG=/tmp/init.log

usage() {
  cat << EOF >&2
Usage: $PROGNAME [-v] [-d <dir>] [-f <file>]
 -b <branch>: branch to pull (default to master)
 -f         : force update and flash
EOF
  exit 1
}

log_date() {
  while IFS= read -r line; do
    echo "$(date) $line"
  done
}

vercomp() {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}


# parse arguments
while getopts fb: o; do
  case $o in
    (f) FORCE=true;;
    (b) BRANCH=$OPTARG;;
    (*) usage
  esac
done

# create log file, if not there
touch $LOG

# get local and remote info
cd $LOCAL
TAG_LOC=$(git describe --tags --abbrev=0)
TAG_REM=$(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags $REMOTE '*.*.*' | tail --lines=1 | cut --delimiter='/' --fields=3)

# check connection
if [ -z "$TAG_REM" ]; then
  echo "Remote returned an empty message. Network might be down. Falling back to remote version 0.0.0"
  TAG_REM=0.0.0
fi

# purge non digit (e.g. initial v)
TAG_REM=$( echo $TAG_REM | sed 's/v//')
TAG_LOC=$( echo $TAG_LOC | sed 's/v//')


# check conditions for execution
if [[ -n "$(find /boot -name 'firstrun*' | head -1)"  || "$FORCE" = "true" ]]; then
  if [ -n "$(find /boot -name 'firstrun*' | head -1)" ]; then
    /usr/bin/rm -f /boot/firstrun* | log_date >> $LOG 2>&1
    # Enables NTP to update date and time from internet
    timedatectl set-ntp True | log_date >> $LOG 2>&1
  fi

  echo " An update on the master branch has been requested."
  vercomp "$TAG_LOC" "$TAG_REM"
  if [ "$?" = "2" ]; then
    echo " Remote version: $TAG_REM is newer than local: $TAG_LOC. Updating..."
    git checkout "$TAG_REM" -b "$TAG_REM"
  else
    echo " Remote version: $TAG_REM, Local version: $TAG_LOC. Already up to date."
    exit
  fi

elif [ "$BRANCH" != "master" ]; then
  echo " An update to the remote branch: $BRANCH, has been requested."
  echo " Pulling remote branch: $BRANCH ..."
  git pull origin "$BRANCH"
  git checkout "$BRANCH"
  FORCE=true

else
  echo "Not a firstrun. Use \"update_v2 sh -f\" to force an update."
  exit
fi

# assume klipper config options have not changed
/usr/bin/make clean | log_date >> $LOG 2>&1
/usr/bin/make | log_date >> $LOG 2>&1

# confirm jumper
while [ "$FORCE" = "true" ]; do
    read -p "Install the BOOT jumper and continue (Y/n): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) break;;
    esac
done

# stop klipper
echo "Stopping Klipper service..."
sudo service klipper stop

# reset board
$HOME/scripts/reset_pin_cycle.sh

# flash
/usr/bin/make serialflash FLASH_DEVICE=/dev/ttyAMA0 | log_date >> $LOG 2>&1

if [ "$FORCE" = "true" ]; then
  read -p "Remove the BOOT jumper and press any key to continue:" jumper
fi

# start klipper
echo "Staring Klipper service..."
sudo service klipper start

echo "All done. Bye"
