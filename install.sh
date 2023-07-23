#!/bin/env bash

root_check() {
    if [[ "$(whoami)" != "root" ]]; then
        echo "ERROR: Run script as root"
        exit 1
    fi
}

backup() {
    printf -- ' -> Creating backup: '
    mkdir -p $(pwd)/backup
    mkdir -p $(pwd)/backup/etc/

    cp /etc/mkinitcpio.conf $(pwd)/backup/etc/mkinitcpio.conf
    printf -- '\033[0m\n'
    return $?
}

prepare_src() {
    printf -- ' -> Prepairing source files: '
    mkdir -p $(pwd)/.tmp
    cp $(pwd)/backup/etc/mkinitcpio.conf $(pwd)/.tmp/mkinitcpio.conf & \
    cp /usr/lib/initcpio/hooks/encrypt $(pwd)/.tmp/encrypt
    printf -- '\033[0m\n'
    return $?
}

patch_hook() {
    printf -- ' -> Patching encrypt hook to cirnocrypt: '
    patch -u $(pwd)/.tmp/encrypt $(pwd)/cirnocrypt.patch > /dev/null
    printf -- '\033[0m\n'
    return $?
}

pick_greeting() {
    # TODO
    patch -u $(pwd)/.tmp/encrypt $(pwd)/greetings/ascii_cirno.patch > /dev/null
    #printf -- '\033[0m\n'
    return
}

patch_mkinitcpio() {
    printf -- ' -> Patching mkinitcpio (encrypt -> cirnocrypt): '
    sed -i '/HOOKS=(/s/\bencrypt/cirnocrypt/g' $(pwd)/.tmp/mkinitcpio.conf
    printf -- '\033[0m\n'
    return $?
}

install() {
    printf -- ' -> Installing: '
    cp $(pwd)/.tmp/mkinitcpio.conf /etc/mkinitcpio.conf & \
    cp $(pwd)/.tmp/encrypt /etc/initcpio/hooks/cirnocrypt
    printf -- '\033[0m\n'
    return $?
}

root_check

backup
prepare_src

patch_hook
pick_greeting
patch_mkinitcpio

install

# Updating initcpio
/usr/bin/mkinitcpio -P

#Cleaning up
/usr/bin/rm -f $(pwd)/.tmp/mkinitcpio.conf
/usr/bin/rm -f $(pwd)/.tmp/encrypt
/usr/bin/rmdir $(pwd)/.tmp 2> /dev/null

exit 0
