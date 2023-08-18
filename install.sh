#!/bin/env bash

### STRINGS
_clear="\033[0m"
_warning="\033[33m\033[1m\033[5m"
_arrow="\033[1m\033[36m->${_clear}"
_green="\033[32m"
_blue="\033[34m"

### UTILS
warning() {
    printf -- "${_warning}WARNING!${_clear} Using this script will modify /etc/mkinitcpio.conf, potentially breaking initcpio.\n"
    printf -- "In case of failure, chroot into the system and restore the mkinitcpio backup or replace the 'cirnocrypt' module with 'encrypt'\n"

    read -p "Type 'y' to continue: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Canceled"
        exit 1
    fi
}
root_check() {
    if [[ "$(whoami)" != "root" ]]; then
        echo "ERROR: Run script as root"
        exit 1
    fi
}

### PREPAIRING
backup() {
    printf -- " ${_arrow} Creating backup${_clear}\n"
    if ! {
        mkdir -p "$(pwd)/backup" &&
        backup_dir="$(pwd)/backup/$(date +'%Y-%m-%d_%H-%M-%S')" &&
        mkdir -p "$backup_dir" &&
        mkdir -p "$backup_dir/etc/"
    }; then
        echo "Unable to create backup folders!"
        exit 1;
    fi

    if ! cp /etc/mkinitcpio.conf "$backup_dir/etc/mkinitcpio.conf"; then
        echo "Unable to create backup of /etc/mkinitcpio.conf!"
        exit 1;
    fi
}
prepare_src() {
    printf -- " ${_arrow} Prepairing source files${_clear}\n"
    if ! {
        mkdir -p $(pwd)/.tmp &&
        mkdir -p $(pwd)/.tmp/hook &&
        mkdir -p $(pwd)/.tmp/install &&
        cp /etc/mkinitcpio.conf $(pwd)/.tmp/mkinitcpio.conf &&
        cp /usr/lib/initcpio/hooks/encrypt $(pwd)/.tmp/hook/encrypt &&
        cp /usr/lib/initcpio/install/encrypt $(pwd)/.tmp/install/encrypt
    }; then
        echo "Unable to prepairing source files! Check permissions in pwd"
        exit 1;
    fi
}

### PATCHES:
patch_hook() {
    printf -- " ${_arrow} Patching encrypt hook${_clear}\n"
    if ! patch -u $(pwd)/.tmp/hook/encrypt $(pwd)/hook.patch; then
        echo "Error: Unable to patch hook"
        exit 1
    fi
}
patch_install() {
    printf -- " ${_arrow} Patching encrypt install script${_clear}\n"
    if ! patch -u $(pwd)/.tmp/install/encrypt $(pwd)/install.patch; then
        echo "Error: Unable to patch install script"
        exit 1
    fi
}
patch_mkinitcpio() {
    printf -- " ${_arrow} Patching mkinitcpio (encrypt -> cirnocrypt)${_clear}\n"
    if ! sed -i '/HOOKS=(/s/\bencrypt/cirnocrypt/g' $(pwd)/.tmp/mkinitcpio.conf; then
        echo "Error: Unable to patch /etc/mkinitcpio.conf"
        exit 1
    fi
}

### POST TRANSACTION
make_greeting() {
    printf -- " ${_arrow} Making greeting${_clear}\n"
    #if [ $# -eq 1 ]; then
    #    selected_greeting="$1"
    # else
        greetings=($(ls $(pwd)/greetings/ | grep -v "\.png$"))
        count=${#greetings[@]}

        printf -- "${_green}  Available greetings:${_clear}\n"
        for ((i = 0; i < count; i++)); do
            printf -- "\t$i - ${_blue}${greetings[i]}${_clear}\n"
        done

        while true; do
            printf -- "Select a greeting ${_green}index${_clear}: "
            read index

            if [ "$index" -ge 0 ] && [ "$index" -lt "$count" ]; then
                selected_greeting="${greetings[index]}"
                break
            else
                echo "Invalid index. Please choose a valid index."
            fi
        done
    #fi
    
    if [ -f "./greetings/$selected_greeting" ]; then
        cp "./greetings/$selected_greeting" "./.tmp/greeting"
        echo "Selected greeting '$selected_greeting' copied."
    else
        echo "Selected greeting '$selected_greeting' not found."
    fi
}
copy() {
    printf -- " ${_arrow} Copying files${_clear}\n"
    if ! {
        cp $(pwd)/.tmp/hook/encrypt /etc/initcpio/hooks/cirnocrypt &&
        cp $(pwd)/.tmp/install/encrypt /etc/initcpio/install/cirnocrypt &&
        touch /etc/initcpio/cirnocrypt &&
        cp $(pwd)/.tmp/greeting /etc/initcpio/cirnocrypt
    }; then
        echo "Error: Unable to copy files to /etc/initcpio!"
        exit 1
    fi

    if ! cp $(pwd)/.tmp/mkinitcpio.conf /etc/mkinitcpio.conf; then
        echo "Error: Unable to copy mkinitcpio.conf to /etc/mkinitcpio.conf!"
        echo "Attempt to restore from backup"
        latest_backup=$(ls -td $(pwd)/backup/* | head -n 1)
        cp $latest_backup/etc/mkinitcpio.conf /etc/mkinitcpio.conf
        exit 1
    fi

    FILES=("/etc/initcpio/cirnocrypt" "/etc/initcpio/hooks/cirnocrypt" "/etc/initcpio/install/cirnocrypt")
    for FILE in "${FILES[@]}"; do
        if ! test -f "$FILE"; then
            echo "Error: $FILE does not exist."
            exit 1
        fi
    done
}
mkinitcpio() {
    printf -- " ${_arrow} Genering initcpio${_clear}\n"
    if ! /usr/bin/mkinitcpio -P; then
        echo "Error: Errors occurred while creating initcpio!"
        echo "Check the cause and restore from backup if needed"
        exit 1
    fi
}
clean() {
    printf -- " ${_arrow} Cleaning up${_clear}\n"
    if ! {
        /usr/bin/rm -f $(pwd)/.tmp/mkinitcpio.conf &&
        /usr/bin/rm -f $(pwd)/.tmp/hook/encrypt &&
        /usr/bin/rm -f $(pwd)/.tmp/install/encrypt &&
        /usr/bin/rmdir $(pwd)/.tmp/hook $(pwd)/.tmp/install/ 2> /dev/null &&
        /usr/bin/rmdir $(pwd)/.tmp 2> /dev/null
    }; then
        echo "Error: Unable to clean up"
        exit 1
    fi
}

###### SCRIPT ######
warning
root_check

backup
prepare_src

patch_hook
patch_install
patch_mkinitcpio

make_greeting
copy
mkinitcpio
clean

exit 0
