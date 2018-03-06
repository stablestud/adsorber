#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:----------   ---default value:--   ---declared in:-------------
# hosts_file_path          /etc/hosts            bin/config.sh, adsorber.conf
# hosts_file_previous_path /etc/hosts.previous   bin/config.sh, adsorber.conf
# prefix_reset             \033[0m               bin/colours.sh
# prefix_title             \033[1;37m            bin/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_CleanUp       bin/remove.sh
# remove_ErrorCleanUp  bin/remove.sh

revert_HostsFile()
{
        if [ -f "${hosts_file_previous_path}" ]; then
                cp "${hosts_file_previous_path}" "${hosts_file_path}" \
                        || {
                                printf "%bCouldn't revert %s.%b" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}"
                                remove_ErrorCleanUp
                                exit 1
                        }
                sed -n -i '/^## This was the hosts file/{n; $p; x; d}; x; 1!p; ${x;p;}' "${hosts_file_path}"    # Remove previous host file notice in hosts file and also the line before
                
                printf "%bSuccessfully reverted %s.\n" "${prefix}" "${hosts_file_path}"
        else
                printf "%bCan't revert hosts file. Previous hosts file does not exist.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi
        
        return 0;
}

revert()
{
        printf "%bReverting %s with %s ...%b\n" "${prefix_title}" "${hosts_file_path}" "${hosts_file_previous_path}" "${prefix_reset}"
        revert_HostsFile
        remove_CleanUp
        
        return 0;
}
