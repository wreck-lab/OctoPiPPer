#!/bin/bash

SELF=$(basename "$0")
ARGS="$*"

LOG=/tmp/init.log

ERR=0
AUTO=false
RESET=true
UPD=true
BRANCH="master"
SCRIPTS=/home/pi/scripts
LOCAL=/home/pi/klipper
REPO_REM="wreck-lab/klipper"
SELF_REM="https://raw.githubusercontent.com/wreck-lab/wrecklabOS/devel/src/modules/wrecklab/filesystem/home/pi/scripts/"$SELF

log_date() {
  while IFS= read -r line; do
    echo "$(date) $line"
  done
}

usage() {
  cat << EOF >&2
Usage: $SELF [-v] [-d <dir>] [-f <file>]
 -b <branch>: branch to pull (default to master)
 -a         : auto, no user prompt
 -r         : no toggle reset
 -u         : no self update
EOF
  exit 1
}

set_time_net() {
  # Enables NTP to update date and time from internet
  timedatectl set-ntp True | log_date >> $LOG 2>&1
}

check_network() {
  echo -n "Checking network connectivity... "
  if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
    echo "OK"
    NET=1
  else
    # no need for echo, will get the error message
    NET=0
  fi
}

check_ver() {
    if [[ $1 == $2 ]]; then
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
        if [[ -z ${ver2[i]} ]]; then
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

update_script() {
  echo "Starting script update... "

  # Download new version
  echo "Downloading latest version... "
  if ! wget -O --quiet --output-document="$SCRIPTS/$SELF.tmp" $SELF_REM ; then
    echo "Failed: Error while trying to wget new version!"
    echo "File requested: https://raw.githubusercontent.com/"$REPO_REM"/master/"$SELF
    exit 1
  fi
  echo "OK"

  # use size to detect new file
  SIZE_LOC=$(stat --printf="%s" "$SCRIPTS/$SELF")
  SIZE_REM=$(stat --printf="%s" "$SCRIPTS/$SELF.tmp")

  if [ "$SIZE_LOC" -eq "$SIZE_REM" ]; then
    echo "Local version already up to date."
    return
  else
    echo "Updating script to latest version... "
  fi

  # Copy over modes from old version
  OCTAL_MODE=$(stat -c '%a' "$SCRIPTS/$SELF")
  if ! chmod $OCTAL_MODE "$SCRIPTS/$SELF.tmp" ; then
    echo "Failed: Error while trying to set mode on $0.tmp."
    exit 1
  fi

  # Spawn update script
  echo '#!/bin/bash
# Overwrite old file with new
if mv "'$SCRIPTS'/'$SELF'.tmp" "'$SCRIPTS'/'$SELF'"; then
  echo "Done. Update complete."
  echo "Restarting..."
  rm $0
  exec /bin/bash "'$SCRIPTS'/'$SELF $ARGS'"
else
  echo "Failed!"
fi' > $SCRIPTS/selfup.sh

  if [ $UPD = "true" ]; then
   echo -n "Inserting update process... "
   exec /bin/bash $SCRIPTS/selfup.sh
 fi
}

update_system() {
  # this update must run in the repo folder

  # get local and remote info
  TAG_LOC=$(git describe --tags --abbrev=0)
  TAG_REM=$(git -c 'versionsort.suffix=-' ls-remote --exit-code --refs --sort='version:refname' --tags "https://github.com/"$REPO_REM '*.*.*' | tail --lines=1 | cut --delimiter='/' --fields=3)

  if [ -z "$TAG_REM" ]; then
    echo "Remote returned an empty message. Network might have gone down. Falling back to remote version 0.0.0"
    TAG_REM=0.0.0
  fi

  # purge non digit (e.g. initial v)
  TAG_REM=$( echo $TAG_REM | sed 's/v//')
  TAG_LOC=$( echo $TAG_LOC | sed 's/v//')

  if [ "$BRANCH" != "master" ]; then
    echo "Update to the remote branch: $BRANCH, requested... "
    echo "Pulling remote branch: $BRANCH ... "
    git pull origin "$BRANCH"
    git checkout "$BRANCH"

  else
    echo "Update on the master branch requested... "
    check_ver "$TAG_LOC" "$TAG_REM"
    if [ "$?" = "2" ]; then
      echo "Remote version: $TAG_REM is newer than local: $TAG_LOC. Updating... "
      git checkout "$TAG_REM" -b "$TAG_REM"
    else
      echo "Remote version: $TAG_REM, Local version: $TAG_LOC. Already up to date."
    fi

  fi
}

update_klipper() {
  # this update must run in the repo folder

  # assume klipper config options have not changed
  /usr/bin/make clean | log_date >> $LOG 2>&1
  /usr/bin/make | log_date >> $LOG 2>&1

  # confirm jumper
  while [ "$AUTO" = "false" ]; do
      read -p "Install the BOOT jumper and continue (Y/n): " yn
      case $yn in
          [Yy]* ) break;;
          [Nn]* ) exit;;
          * ) break;;
      esac
  done

  # stop klipper
  echo -n "Stopping Klipper service... "
  sudo service klipper stop
  echo "OK"

  # reset board
  if [ "$RESET" = "true" ]; then
    $SCRIPTS/reset_pin_cycle.sh
  fi

  # flash
  /usr/bin/make serialflash FLASH_DEVICE=/dev/ttyAMA0
  ERR=$?

  if [ "$ERR" -ne "0" ]; then
    echo "ERROR flashing the board !!!" | log_date >> $LOG 2>&1
  fi

  if [ "$AUTO" = "false" ]; then
    read -p "Remove the BOOT jumper and press any key to continue: " jumper
  fi

  # start klipper
  echo -n "Starting Klipper service... "
  sudo service klipper start
  echo "OK"

}


## SCRIPT STARTS HERE

# parse arguments
while getopts arub: o; do
  case $o in
    (b) BRANCH=$OPTARG;;
    (a) AUTO=true;;
    (r) RESET=false;;
    (u) UPD=false;;
    (*) usage
  esac
done

echo "Updating... "

# check connectivity first
check_network

# only if online, look for updates
if [ $NET -eq "1" ]; then
  update_script
  cd $LOCAL
  update_system
fi

cd $LOCAL
update_klipper

echo "Done"
exit $ERR
