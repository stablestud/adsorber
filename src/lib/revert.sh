#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Variable naming:
# under_score        - used for global variables which are accessible between functions.
# _extra_under_score - used for local function variables. Should be unset afterwards.
#          (Note the underscore in the beginning of _extra_under_score!)

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:------------  ---default value:--  ---declared in:----------------
# hosts_file_path           /etc/hosts           src/lib/config.sh, adsorber.conf
# hosts_file_previous_path  /etc/hosts.previous  src/lib/config.sh, adsorber.conf
# prefix                    '  ' (two spaces)    src/lib/colours.sh
# prefix_fatal              '\033[0;91mE '       src/lib/colours.sh
# prefix_reset              \033[0m              src/lib/colours.sh
# prefix_title              \033[1;37m           src/lib/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-------  ---function defined in:---
# remove_CleanUp       src/lib/remove.sh
# remove_ErrorCleanUp  src/lib/remove.sh

# shellcheck disable=SC2154

revert_HostsFile()
{
        if [ -f "${hosts_file_previous_path}" ]; then
                # Copy /etc/hosts.previous to /etc/hosts, replacing the current one
                cp "${hosts_file_previous_path}" "${hosts_file_path}" \
                        || {
                                printf "%bCouldn't revert %s.%b" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}"
                                remove_ErrorCleanUp
                                exit 1
                        }

                # Remove previous host file notice from /etc/hosts.previous in /etc/hosts and also the line before
                sed -n -i '/^## This was the hosts file/{n; $p; x; d}; x; 1!p; ${x;p;}' "${hosts_file_path}"

                printf "%bSuccessfully reverted %s.\\n" "${prefix}" "${hosts_file_path}"
        else
                # If /etc/hosts.previous was not found, abort and call error clean-up function
                printf "%bCan't revert hosts file. Previous hosts file does not exist.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi

        return 0;
}


# Main function of revert.sh
revert()
{
        printf "%bReverting %s with %s ...%b\\n" "${prefix_title}" "${hosts_file_path}" "${hosts_file_previous_path}" "${prefix_reset}"
        revert_HostsFile
        remove_CleanUp

        return 0;
}
