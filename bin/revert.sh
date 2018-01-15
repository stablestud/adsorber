#!/bin/bash

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared in adsorber.conf, adsorber.sh or bin/config.sh.
# If you run this file independently following variables need to be set:
# ---variable:----------   ---default value:--   ---declared in:-------------
# COLOUR_RESET             \033[0m               bin/colours.sh
# HOSTS_FILE_PATH          /etc/hosts            adsorber.conf, bin/config.sh
# HOSTS_FILE_BACKUP_PATH   /etc/hosts.original   adsorber.conf, bin/config.sh
# PREFIX                   '  ' (two spaces)     bin/colours.sh
# PREFIX_TITLE             \033[1;37m            bin/colours.sh
# PREFIX_WARNING           '- '                  bin/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to emulated:
# ---function:-----  ---function defined in:---
# cleanUp            bin/remove.sh
# errorCleanUp       bin/remove.sh


revertHostsFile() {
    if [ -f "${HOSTS_FILE_BACKUP_PATH}" ]; then
        cp "${HOSTS_FILE_BACKUP_PATH}" "${HOSTS_FILE_PATH}" \
            && echo "${PREFIX}Successfully reverted ${HOSTS_FILE_PATH}." \
            && echo "${PREFIX}To reapply please run './adsorber.sh update'."
    else
        echo -e "${PREFIX_FATAL}Can not restore hosts file. Original hosts file does not exist.${COLOUR_RESET}" 1>&2
        errorCleanUp
        exit 1
    fi

    return 0
}


revert() {
    echo -e "${PREFIX_TITLE}Reverting ${HOSTS_FILE_PATH} ...${COLOUR_RESET}"
    revertHostsFile
    cleanUp

    return 0
}
