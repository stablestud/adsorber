#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Variable naming:
# under_score        - used for global variables which are accessible between functions.
# _extra_under_score - used for temporary function variables. Should be unset afterwards.
#          (Note the underscore in the beginning of _extra_under_score!)

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:--------------  ---default value:------------  ---declared in:----
# config_dir_path             ${executable_dir_path}/../../  src/bin/adsorber
# hosts_file_backup_path      /etc/hosts.original            src/lib/config.sh, adsorber.conf
# hosts_file_path             /etc/hosts                     src/lib/config.sh, adsorber.conf
# hosts_file_previous_enable  true                           src/lib/config.sh, adsorber.conf
# hosts_file_previous_path    /etc/hosts.previous            src/lib/config.sh, adsorber.conf
# http_proxy                  Null (not set)                 src/lib/config.sh, adsorber.conf
# https_proxy                 Null (not set)                 src/lib/config.sh, adsorber.conf
# ignore_download_error       true                           src/lib/config.sh, adsorber.conf
# prefix                      '  ' (two spaces)              src/lib/colours.sh
# prefix_fatal                '\033[0;91mE '                 src/lib/colours.sh
# prefix_info                 '\033[0;97m  '                 src/lib/colours.sh
# prefix_input                '  ' (two spaces)              src/lib/colours.sh
# prefix_reset                \033[0m                        src/lib/colours.sh
# prefix_title                \033[1;37m                     src/lib/colours.sh
# prefix_warning              '- '                           src/lib/colours.sh
# primary_list                blacklist                      src/lib/config.sh, adsorber.conf
# reply_to_force_prompt       Null (not set)                 src/lib/setup.sh, src/bin/adsorber
# tmp_dir_path                /tmp/adsorber                  src/bin/adsorber
# use_partial_matching        true                           src/lib/config.sh, adsorber.conf
# version                     0.2.2 or similar               src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# --function:--  ---function defined in:---
# cleanUp        src/lib/cleanup.sh
# errorCleanUp   src/lib/cleanup.sh

# shellcheck disable=SC2154

begin_section="# BEGIN OF ADSORBER SECTION"
end_section="# END OF ADSORBER SECTION"

update_CheckBackupExist()
{
        if [ ! -f "${hosts_file_backup_path}" ]; then
                # The user may proceed without having a backup of the original
                # hosts file, however it's not recommended to proceed as the
                # hostname association with 127.0.0.1 and localhost will be lost.
                # The user may interactively decide here wheter to proceed or not.
                if [ -z "${reply_to_force_prompt}" ]; then
                        printf "%bBackup of %s does not exist. To backup run 'adsorber enable'.%b\\n" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}" 1>&2
                        printf "%bIgnore issue and continue? (May break your hostfile, not recommended) [y/N]: %b" "${prefix_input}" "${prefix_reset}"
                        read -r reply_to_force_prompt
                fi

                case "${reply_to_force_prompt}" in
                        [Yy] | [Yy][Ee][Ss] )
                                return 0
                                ;;
                        * )
                                printf "%bAborted.\\n" "${prefix_warning}" 1>&2
                                errorCleanUp
                                exit 130
                                ;;
                esac
        fi
}


update_CreateTmpDir()
{
        # Create a temporary folder in which Adsorber can manipulate files
        # without distracting the environment
        if [ ! -d "${tmp_dir_path}" ]; then
                mkdir "${tmp_dir_path}" \
                        || {
                                printf "%bCannot create tmp dir '${tmp_dir_path}'%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                                exit 1
                        }
        elif [ ! -s "${tmp_dir_path}/config-filtered" ]; then
                echo "${prefix}Removing previous tmp folder ..."
                rm -rf "${tmp_dir_path}"
                mkdir "${tmp_dir_path}"
        fi
}


update_CreateCacheDir()
{
        # Cache dir is used to save the previous host domains
        if [ ! -d "${cache_dir_path}" ]; then
                mkdir "${cache_dir_path}" \
                        || {
                                printf "%bCannot create cache dir '${cache_dir_path}'%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                                errorCleanUp
                                exit 130
                        }
        fi
}

update_ReadSourceList()
{
        # Read the sources.list (by default located at /usr/local/etc/adsorber)
        # which holds the URLs to the remote hosts files
        if [ ! -s "${config_dir_path}/sources.list" ]; then

                if [ ! -s "${config_dir_path}/blacklist" ]; then
                        printf "%bMissing 'sources.list' and blacklist. To fix run 'adsorber enable'.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        exit 127
                fi

                echo "${prefix}No sources to fetch from, ignoring ..." 1>&2
                return 1
        else
                # Only read sources with http(s) at the beginning
                # Remove inline # comments
                sed -n '/^\s*http.*/p' "${config_dir_path}/sources.list" \
                        | sed 's/\s\+#.*//g' \
                        > "${tmp_dir_path}/sourceslist-filtered"

                if [ ! -s "${tmp_dir_path}/sourceslist-filtered" ]; then
                        echo "${prefix}No hosts set in sources.list, ignoring ..."
                        return 1
                fi

        fi
}


update_ReadWhiteList()
{
        # Read whitelist to get the domains which should not be blocked
        if [ ! -f "${config_dir_path}/whitelist" ]; then
                echo "${prefix}Whitelist does not exist, ignoring ..." 1>&2
                return 1
        else
                cp "${config_dir_path}/whitelist" "${tmp_dir_path}/whitelist"

                # Filter and sort the whitelist and place the result into the
                # temporary folder (by default /tmp/adsorber)
                update_FilterDomains "whitelist" "whitelist-filtered"
                update_SortDomains "whitelist-filtered" "whitelist-sorted"
        fi
}


update_ReadBlackList()
{
        # Read blacklist to get the domains which should be blocked explicitly
        if [ ! -f "${config_dir_path}/blacklist" ]; then
                echo "${prefix}Blacklist does not exist, ignoring ..." 1>&2
                return 1
        else
                cp "${config_dir_path}/blacklist" "${tmp_dir_path}/blacklist"

                # Filter and sort the blacklist and place the result into the
                # temporary folder (by default /tmp/adsorber)
                update_FilterDomains "blacklist" "blacklist-filtered"
                update_SortDomains "blacklist-filtered" "blacklist-sorted"
        fi
}


update_FetchSources()
{
        _total_count=0
        _successful_count=0

        if [ -n "${http_proxy}" ]; then
                echo "${prefix}Using HTTP proxy: ${http_proxy}"
        fi

        if [ -n "${https_proxy}" ]; then
                echo "${prefix}Using HTTPS proxy: ${https_proxy}"
        fi

        # Read the links line by line from filtered sources.list
        while read -r _domain; do
                _total_count=$((_total_count+1))

                printf "%bGetting%b: %s\\n" "${prefix_info}" "${prefix_reset}" "${_domain}"
                # Is curl installed? If yes download the hosts files.
                if command -v curl 2>/dev/null 1>&2; then
                        if curl "${_domain}" -sS -L --connect-timeout 30 --fail --retry 1 >> "${tmp_dir_path}/fetched"; then
                                _successful_count=$((_successful_count+1))
                        else
                                printf "%bcurl couldn't fetch: %s\\n" "${prefix_warning}" "${_domain}" 1>&2
                        fi
		# Is wget2 installed? If yes download the hosts file.
		# We check for wget2 first, because some distros symlink wget2 to wget,
		# but it's not parameter compatible to wget v1, breaking download
		elif command -v wget2 2>/dev/null 1>&2; then
			if wget2 "${_domain}" --force-progress --timeout=30 --tries 1 --no-verbose --output-document=- >> "${tmp_dir_path}/fetched"; then
				_successful_count=$((_successful_count+1))
			else
				printf "%bwget2 couldn't fetch: %s\\n" "${prefix_warning}" "${_domain}" 1>&2
			fi
                # Is wget installed? If yes download the hosts files.
                elif command -v wget 2>/dev/null 1>&2; then
                        printf "%s" "${prefix}"

                        if wget "${_domain}" --show-progress -L --timeout=30 -t 1 -nv -O - >> "${tmp_dir_path}/fetched"; then
                                _successful_count=$((_successful_count+1))
                        else
                                printf "%bwget couldn't fetch: %s\\n" "${prefix_warning}" "${_domain}" 1>&2
                        fi
                # If neither wget nor curl is installed abort and clean up.
                else
                        printf "%bNeither curl nor wget installed. Can't continue.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2

                        errorCleanUp
                        exit 2
                fi

        done < "${tmp_dir_path}/sourceslist-filtered"

        unset _domain

        if [ "${ignore_download_error}" = "false" ] && [ "${_successful_count}" -ne "${_total_count}" ]; then
                printf "%bCouldn't fetch all hosts sources [%d/%d]. Aborting ...\\n" "${prefix_warning}" "${_successful_count}" "${_total_count}" 1>&2

                errorCleanUp 
                exit 1
        elif [ "${_successful_count}" -eq 0 ]; then
                printf "%bNothing to apply [%d/%d].\\n" "${prefix_warning}" "${_successful_count}" "${_total_count}" 1>&2
                echo "${prefix}Perhaps a proxy server must be set?" 1>&2
                return 1
        else
                printf "%bSuccessfully fetched %d out of %d hosts sources.%b\\n" "${prefix_info}" "${_successful_count}" "${_total_count}" "${prefix_reset}"
        fi

        # Unset temporary function variables.
        unset _total_count
        unset _successful_count
}


update_FilterDomains()
{
        _input_file="${1}"
        _output_file="${2}"

        # - replace OSX '\r' (CR) and MS-DOS '\r\n' (CR,LF) with Unix '\n' (LF) (newline)
        # - replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
        # - only keep lines starting with 0.0.0.0
        # - remove inline '#' comments
        # - replace tabs and multiple spaces with one space
        # - remove domains without a dot (e.g localhost , loopback , ip6-allnodes , etc...)
        # - remove domains that are ending with *.local
        sed 's/\r/\n/g' "${tmp_dir_path}/${_input_file}" \
                | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
                | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
                | sed 's/\s\+#.*//g' \
                | sed 's/[[:blank:]]\+/ /g' \
                | sed -n '/^0\.0\.0\.0\s.\+\..\+/p' \
                | sed -n '/\.local\s*$/!p' \
                > "${tmp_dir_path}/${_output_file}"

        unset _input_file
        unset _output_file
}


update_SortDomains()
{
        _input_file="${1}"
        _output_file="${2}"

        # Sort the domains by alphabet and also remove duplicates
        sort "${tmp_dir_path}/${_input_file}" -f -u -o "${tmp_dir_path}/${_output_file}"

        unset _input_file
        unset _output_file
}


update_ApplyWhiteList()
{
        if [ ! -s "${tmp_dir_path}/whitelist-sorted" ]; then
                echo "${prefix}Whitelist is empty, ignoring ..."
                return 1
        else
                echo "${prefix}Applying whitelist ..."

                sed -i 's/^0\.0\.0\.0\s\+//g' "${tmp_dir_path}/whitelist-sorted"
                cp "${tmp_dir_path}/cache" "${tmp_dir_path}/applied-whitelist"

                while read -r _domain; do

                        if [ "${use_partial_matching}" = "true" ]; then
                                # Filter out domains from whitelist, also for sub-domains
                                sed -i "/\\.*${_domain}$/d" "${tmp_dir_path}/applied-whitelist"
                        else
                                # Filter out domains from whitelist, ignoring sub-domains
                                sed -i "/\\s\\+${_domain}$/d" "${tmp_dir_path}/applied-whitelist"
                        fi

                done < "${tmp_dir_path}/whitelist-sorted"

                unset _domain

                cp "${tmp_dir_path}/applied-whitelist" "${tmp_dir_path}/cache"
        fi

}


update_MergeBlackList()
{
        if [ ! -s "${tmp_dir_path}/blacklist-sorted" ]; then
                echo "${prefix}Blacklist is empty, ignoring ..."
                return 1
        else
                echo "${prefix}Applying blacklist ..."

                cat "${tmp_dir_path}/cache" "${tmp_dir_path}/blacklist-sorted" >> "${tmp_dir_path}/merged-blacklist"

                update_FilterDomains "merged-blacklist" "merged-blacklist-filtered"
                update_SortDomains "merged-blacklist-filtered" "merged-blacklist-sorted"

                cp "${tmp_dir_path}/merged-blacklist-sorted" "${tmp_dir_path}/cache"
        fi
}


update_IsCacheEmpty()
{
        if [ ! -s "${tmp_dir_path}/cache" ]; then
                printf "%bNothing to apply.\\n" "${prefix_warning}" 1>&2
                cleanUp
                exit 1
        fi
}


update_CreateAdsorberLines()
{
        {
                # Replace #@...@# with variables
                sed "s|#@version@#|${version}|g" "${shareable_dir_path}/components/hosts_header" \
                        | sed "s|#@date@#|$(date +'%b %e %X')|g" \
                        | sed "s|#@blocked@#|$(wc -l < "${tmp_dir_path}/cache")|g" \
                        | sed "s|#@hosts_file_backup_path@#|${hosts_file_backup_path}|g"

                echo

                # Add the fetched ad-domains to the hosts file
                cat "${tmp_dir_path}/cache"

                echo

                # Add the hosts_header to the hosts file in the temporary folder, filter out the line with @ and replace with hosts_file_backup_path
                sed "s|#@version@#|${version}|g" "${shareable_dir_path}/components/hosts_header" \
                        | sed "s|#@date@#|$(date +'%b %e %X')|g" \
                        | sed "s|#@blocked@#|$(wc -l < "${tmp_dir_path}/cache")|g" \
                        | sed "s|#@hosts_file_backup_path@#|${hosts_file_backup_path}|g"

        } > "${tmp_dir_path}/adsorber.hosts"
}


update_PreviousHostsFile()
{
        # Check if we should backup the previous hosts file
        if [ "${hosts_file_previous_enable}" = "true" ]; then
                echo "${prefix}Creating backup of current ad-domains"

                if [ -f "${cache_dir_path}/adsorber.hosts" ]; then
                        cp "${cache_dir_path}/adsorber.hosts" "${cache_dir_path}/adsorber.hosts.old"
                fi
                cp "${tmp_dir_path}/adsorber.hosts" "${cache_dir_path}" \
                        || {
                                printf "%bCouldn't create previous hosts file to %s%b\\n" "${prefix_fatal}" "${cache_path}/adsorber.lines" "${prefix_reset}" 1>&2
                                errorCleanUp
                                exit 1
                        }
        fi
}


update_RemoveAdsorberLines()
{
        sed "/${begin_section}/,/${end_section}/d" "${tmp_dir_path}/hosts.old" > "${tmp_dir_path}/hosts.clean"
}


update_AddAdsorberLines()
{
        update_RemoveAdsorberLines

        {
                cat "${tmp_dir_path}/hosts.clean"
                echo "${begin_section}"
                cat "${tmp_dir_path}/adsorber.hosts"
                echo "${end_section}"
        } >> "${tmp_dir_path}/hosts.new"
}


update_ApplyHostsFile()
{
        echo "${prefix}Applying new hosts file ..."
        
        cp "${hosts_file_path}" "${tmp_dir_path}/hosts.old"

        update_AddAdsorberLines

        # Replace systems hosts file with the modified version from /tmp/adsorber
        cp "${tmp_dir_path}/hosts.new" "${hosts_file_path}" \
                || {
                        printf "%b" "${prefix_fatal}Couldn't apply hosts file. Aborting.${prefix_reset}\\n" 1>&2
                        errorCleanUp
                        exit 126
                }

        printf "%bSuccessfully applied new hosts file with %d blocked domains.%b\\n" "${prefix_info}" "$(wc -l < "${tmp_dir_path}/cache")" "${prefix_reset}"
}


# Main function of update.sh. This is like an index in what order the functions
# should be run
update()
{
        printf "%bUpdating %s ...%b\\n" "${prefix_title}" "${hosts_file_path}" "${prefix_reset}"

        update_CheckBackupExist
        update_CreateTmpDir
        update_CreateCacheDir
        update_ReadBlackList
        update_ReadWhiteList

        if update_ReadSourceList; then
                if update_FetchSources; then
                        update_FilterDomains "fetched" "fetched-filtered"
                        update_SortDomains "fetched-filtered" "fetched-sorted"
                        cp "${tmp_dir_path}/fetched-sorted" "${tmp_dir_path}/cache"
                else
                        # Create empty cache file for the ad-domains.
                        touch "${tmp_dir_path}/cache"
                fi
        else
                # Create empty cache file for the ad-domains.
                touch "${tmp_dir_path}/cache"
        fi

        case "${primary_list}" in
                whitelist )
                        update_MergeBlackList
                        update_ApplyWhiteList
                        ;;
                blacklist )
                        update_ApplyWhiteList
                        update_MergeBlackList
                        ;;
                * )
                        printf "%bWrong primary_list set in adsorber.conf. Choose either 'whitelist' or 'blacklist'%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        errorCleanUp
                        exit 127
                        ;;
        esac

        update_IsCacheEmpty
        update_CreateAdsorberLines
        update_PreviousHostsFile
        update_ApplyHostsFile
        cleanUp
}
