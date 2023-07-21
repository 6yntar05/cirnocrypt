#!/bin/env bash

#
if [[ "$(whoami)" != "root" ]]; then
  echo "ERROR: Run script as root"
  exit 1
fi

# TODO
  # Picking greetings

#
printf "Backing up mkinitcpio.conf "
mkdir -p $(pwd)/backup
cp /etc/mkinitcpio.conf $(pwd)/backup/mkinitcpio.conf
if [[ $? -eq 0 ]]; then printf '✓'; else printf '✗'; fi
printf '\n'

#
printf "Copying the original 'encrypt' hook "
cp /usr/lib/initcpio/install/encrypt /etc/initcpio/install/cirnocrypt
if [[ $? -eq 0 ]]; then printf '✓'; else printf '✗'; fi
printf ' '
cp /usr/lib/initcpio/hooks/encrypt /etc/initcpio/hooks/cirnocrypt
if [[ $? -eq 0 ]]; then printf '✓'; else printf '✗'; fi
printf '\n'

#
printf "Patching 'encrypt' hook "
patch -u /etc/initcpio/hooks/cirnocrypt cirnocrypt.patch > /dev/null
if [[ $? -eq 0 ]]; then printf '✓'; else printf '✗'; fi
printf ' '
  # By choosen greeting
patch -u /etc/initcpio/hooks/cirnocrypt greetings/ascii_cirno.patch > /dev/null
if [[ $? -eq 0 ]]; then printf '✓'; else printf '✗'; fi
printf '\n'

# TODO:
  #printf "Patching mkinitcpio.conf"
  # rg HOOK # sed 's/encrypt/cirnocrypt/g' install.sh

  # Updating mkinitcpio
  #mkinitcpio -P

exit 0
