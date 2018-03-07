#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:----------   ---default value:--   ---declared in:-------------
# hosts_file_path          /etc/hosts            bin/config.sh, adsorber.conf
# hosts_file_backup_path   /etc/hosts.original   bin/config.sh, adsorber.conf
# prefix                   '  ' (two spaces)     bin/colours.sh
# prefix_reset             \033[0m               bin/colours.sh
# prefix_title             \033[1;37m            bin/colours.sh
# prefix_warning           '- '                  bin/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_CleanUp       bin/remove.sh
# remove_ErrorCleanUp  bin/remove.sh


restore_HostsFile()
{
        if [ -f "${hosts_file_backup_path}" ]; then
                cp "${hosts_file_backup_path}" "${hosts_file_path}" \
                        && {
                                printf "%bSuccessfully restored %s.\n" "${prefix}" "${hosts_file_path}"
                                printf "%bTo reapply please run './adsorber.sh update'.\n" "${prefix}"
                        }
        else
                printf "%bCan't restore hosts file. Original hosts file does not exist.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi

        return 0
}


restore()
{
        printf "%bRestoring %s ...%b\n" "${prefix_title}" "${hosts_file_path}" "${prefix_reset}"
        restore_HostsFile
        remove_CleanUp

        return 0
}
