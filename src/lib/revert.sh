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
# --function:--------------  ---function defined in:---
# cleanUp                    src/lib/cleanup.sh
# errorCleanUp               src/lib/cleanup.sh
# update_CreateTmpDir        src/lib/update.sh
# update_RemoveAdsorberLines src/lib/update.sh

# shellcheck disable=SC2154

revert_HostsFile()
{
        if [ -f "${cache_dir_path}/adsorber.hosts.old" ]; then
                update_CreateTmpDir \
                        && cp "${hosts_file_path}" "${tmp_dir_path}/hosts.old" \
                        && update_RemoveAdsorberLines \
                        && cp "${cache_dir_path}/adsorber.hosts.old" "${tmp_dir_path}/adsorber.hosts" \
                        && update_AddAdsorberLines \
                        && cp "${tmp_dir_path}/hosts.new" "${hosts_file_path}" \
                        || {
                                printf "%bCouldn't revert %s.%b" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}"
                                errorCleanUp
                                exit 1
                        }

                cp "${cache_dir_path}/adsorber.hosts" "${cache_dir_path}/adsorber.hosts.old"
                cp "${tmp_dir_path}/adsorber.hosts" "${cache_dir_path}/adsorber.hosts"

                printf "%bSuccessfully reverted %s.\\n" "${prefix}" "${hosts_file_path}"
        elif [ -f "${cache_dir_path}/adsorber.hosts" ]; then
		# Fallback if actual previous ad-domains save does not exist
		update_CreateTmpDir \
                        && cp "${hosts_file_path}" "${tmp_dir_path}/hosts.old" \
                        && update_RemoveAdsorberLines \
                        && cp "${cache_dir_path}/adsorber.hosts" "${tmp_dir_path}/adsorber.hosts" \
                        && update_AddAdsorberLines \
                        && cp "${tmp_dir_path}/hosts.new" "${hosts_file_path}" \
                        || {
                                printf "%bCouldn't revert %s.%b" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}"
                                errorCleanUp
                                exit 1
                        }
	else
                # If /etc/hosts.previous was not found, abort and call error clean-up function
                printf "%bCannot revert to previous ad-domains.. Previous save '${cache_dir_path}/adsorber.hosts.old' does not exist.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                errorCleanUp
                exit 1
        fi
}


# Main function of revert.sh
revert()
{
        printf "%bReverting %s with %s ...%b\\n" "${prefix_title}" "${hosts_file_path}" "${hosts_file_previous_path}" "${prefix_reset}"
        revert_HostsFile
        cleanUp
}
