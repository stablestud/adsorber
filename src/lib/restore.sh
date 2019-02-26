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
# ---variable:----------   ---default value:--   ---declared in:----------------
# hosts_file_path          /etc/hosts            src/lib/config.sh, adsorber.conf
# hosts_file_backup_path   /etc/hosts.original   src/lib/config.sh, adsorber.conf
# prefix                   '  ' (two spaces)     src/lib/colours.sh
# prefix_fatal             '\033[0;91mE '        src/lib/colours.sh
# prefix_reset             \033[0m               src/lib/colours.sh
# prefix_title             \033[1;37m            src/lib/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:------------  ---function defined in:---
# cleanUp                   src/lib/cleanup.sh
# errorCleanUp              src/lib/cleanup.sh
# update_PreviousHostsFile  src/lib/update.sh

# shellcheck disable=SC2154

restore_HostsFile()
{
        if [ -f "${hosts_file_backup_path}" ]; then
                update_PreviousHostsFile
                # Copy /etc/hosts.original to /etc/hosts, replacing the current one
                cp "${hosts_file_backup_path}" "${hosts_file_path}" \
                        || {
                                printf "%bCouldn't restore %s.%b" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}"
                                errorCleanUp
                                exit 1
                        }

                printf "%bSuccessfully restored %s.\\n" "${prefix}" "${hosts_file_path}"
                printf "%bTo reapply please run 'adsorber update'.\\n" "${prefix}"
        else
                # If /etc/hosts.previous was not found, abort and call error clean-up function
                printf "%bCan't restore original hosts file. Original hosts file does not exist.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                errorCleanUp
                exit 1
        fi

        return 0
}


# Main function of restore.sh
restore()
{
        printf "%bRestoring %s ...%b\\n" "${prefix_title}" "${hosts_file_path}" "${prefix_reset}"
        restore_HostsFile
        cleanUp

        return 0
}
