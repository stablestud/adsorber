#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:----------   ---default value:-----------   ---declared in:-------------
# hosts_file_path          /etc/hosts                     bin/config.sh, adsorber.conf
# hosts_file_backup_path   /etc/hosts.original            bin/config.sh, adsorber.conf
# ignore_download_error    true                           bin/config.sh, adsorber.conf
# prefix                   '  ' (two spaces)              bin/colours.sh
# prefix_fatal             '\033[0;91mE '                 bin/colours.sh
# prefix_info              '\033[0;97m  '                 bin/colours.sh
# prefix_input             '  ' (two spaces)              bin/colours.sh
# prefix_reset             \033[0m                        bin/colours.sh
# prefix_title             \033[1;37m                     bin/colours.sh
# prefix_warning           '- '                           bin/colours.sh
# primary_list             blacklist                      bin/config.sh, adsorber.conf
# http_proxy               Null (not set)                 bin/config.sh, adsorber.conf
# https_proxy              Null (not set)                 bin/config.sh, adsorber.conf
# reply_to_force_prompt    Null (not set)                 bin/install.sh, adsorber.sh
# script_dir_path          script root directory          adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# sourcelist_file_path     script_dir_path/sources.list   adsorber.sh
#   (e.g., /home/user/Downloads/absorber/sources.list)
# tmp_dir_path             /tmp/adsorber                  adsorber.sh
# use_partial_matching     true                           bin/config.sh, adsorber.conf

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_CleanUp       bin/remove.sh
# remove_ErrorCleanUp  bin/remove.sh


update_CheckBackupExist()
{
        if [ ! -f "${hosts_file_backup_path}" ]; then

                if [ -z "${reply_to_force_prompt}" ]; then
                        printf "%bBackup of %s does not exist. To backup run '%s install'.%b\n" "${prefix_fatal}" "${hosts_file_path}" "${0}" "${prefix_reset}" 1>&2
                        printf "%bIgnore issue and continue? (May break your system, not recommended) [YES/n]: %b" "${prefix_input}" "${prefix_reset}"
                        read -r reply_to_force_prompt
                fi

                case "${reply_to_force_prompt}" in
                        [Yy][Ee][Ss] )
                                return 0
                                ;;
                        * )
                                printf "%bAborted.\n" "${prefix_warning}" 1>&2
                                remove_ErrorCleanUp
                                exit 130
                                ;;
                esac
        fi

        return 0
}


update_CreateTmpDir()
{
        if [ ! -d "${tmp_dir_path}" ]; then
                mkdir "${tmp_dir_path}"
        elif [ ! -s "${tmp_dir_path}/config-filtered" ]; then
                echo "${prefix}Removing previous tmp folder ..."
                rm -rf "${tmp_dir_path}"
                mkdir "${tmp_dir_path}"
        fi

        return 0
}


update_ReadSourceList()
{
        if [ ! -s "${sourcelist_file_path}" ]; then

                if [ ! -s "${script_dir_path}/blacklist" ]; then
                        printf "%bMissing 'sources.list' and blacklist. To fix run '%s install'.%b\n" "${prefix_fatal}" "${0}" "${prefix_reset}" 1>&2
                        exit 127
                fi

                echo "${prefix}No sources to fetch from, ignoring ..."
                return 1
        else
                # Only read sources with http(s) at the beginning
                # Remove inline # comments
                sed -n '/^\s*http.*/p' "${sourcelist_file_path}" \
                        | sed 's/\s\+#.*//g' \
                        > "${tmp_dir_path}/sourceslist-filtered"

                if [ ! -s "${tmp_dir_path}/sourceslist-filtered" ]; then
                        echo "${prefix}No hosts set in sources.list, ignoring ..."
                        return 1
                fi

        fi

        return 0
}


update_ReadWhiteList()
{
        if [ ! -f "${script_dir_path}/whitelist" ]; then
                echo "${prefix}Whitelist does not exist, ignoring ..." 1>&2
                return 1
        else
                cp "${script_dir_path}/whitelist" "${tmp_dir_path}/whitelist"

                update_FilterDomains "whitelist" "whitelist-filtered"
                update_SortDomains "whitelist-filtered" "whitelist-sorted"
        fi

        return 0
}


update_ReadBlackList()
{
        if [ ! -f "${script_dir_path}/blacklist" ]; then
                echo "${prefix}Blacklist does not exist, ignoring ..." 1>&2
                return 1
        else
                cp "${script_dir_path}/blacklist" "${tmp_dir_path}/blacklist"

                update_FilterDomains "blacklist" "blacklist-filtered"
                update_SortDomains "blacklist-filtered" "blacklist-sorted"
        fi

        return 0
}


update_FetchSources()
{
        total_count=0
        successful_count=0

        if [ ! -z "${http_proxy}" ]; then
                echo "${prefix}Using HTTP proxy: ${http_proxy}"
        fi

        if [ ! -z "${https_proxy}" ]; then
                echo "${prefix}Using HTTPS proxy: ${https_proxy}"
        fi

        while read -r domain; do
                total_count=$((total_count+1))

                printf "%bGetting%b: %s\n" "${prefix_info}" "${prefix_reset}" "${domain}"

                # Is wget installed? If yes download the hosts files.
                if command -v wget 2>/dev/null 1>&2; then
                        printf "%s" "${prefix}"

                        if wget "${domain}" --show-progress -L --timeout=30 -t 1 -nv -O - >> "${tmp_dir_path}/fetched"; then
                                successful_count=$((successful_count+1))
                        else
                                printf "%bwget couldn't fetch: %s\n" "${prefix_warning}" "${domain}" 1>&2
                        fi
                        # Is curl installed? If yes download the hosts files.
                elif command -v curl 2>/dev/null 1>&2; then
                        if curl "${domain}" -sS -L --connect-timeout 30 --fail --retry 1 >> "${tmp_dir_path}/fetched"; then
                                successful_count=$((successful_count+1))
                        else
                                printf "%bCurl couldn't fetch %s\n" "${prefix_warning}" "${domain}" 1>&2
                        fi
                else
                        printf "%bNeither curl nor wget installed. Can't continue.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        remove_ErrorCleanUp
                        exit 2
                fi

        done < "${tmp_dir_path}/sourceslist-filtered"

        if [ "${successful_count}" -eq 0 ]; then
                printf "%bNothing to apply [%d/%d].\n" "${prefix_warning}" "${successful_count}" "${total_count}" 1>&2
                return 1
        elif [ "${ignore_download_error}" = "false" ] && [ ! "${successful_count}" = "${total_count}" ]; then
                printf "%bCouldn't fetch all hosts sources [%d/%d]. Aborting ...\n" "${prefix_warning}" "${successful_count}" "${total_count}" 1>&2
                remove_ErrorCleanUp
                exit 1
        else
                printf "%bSuccessfully fetched %d out of %d hosts sources.%b\n" "${prefix_info}" "${successful_count}" "${total_count}" "${prefix_reset}"
        fi

        unset total_count
        unset successful_count
        return 0
}


update_FilterDomains()
{
        input_file="${1}"
        output_file="${2}"

        # - replace OSX '\r' and MS-DOS '\r\n' with Unix '\n' (linebreak)
        # - replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
        # - only keep lines starting with 0.0.0.0
        # - remove inline '#' comments
        # - replace tabs and multiple spaces with one space
        # - remove domains without a dot (e.g localhost , loopback , ip6-allnodes , etc...)
        # - remove domains that are redirecting to *.local
        sed 's/\r/\n/g' "${tmp_dir_path}/${input_file}" \
                | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
                | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
                | sed 's/\s\+#.*//g' \
                | sed 's/[[:blank:]]\+/ /g' \
                | sed -n '/^0\.0\.0\.0\s.\+\..\+/p' \
                | sed -n '/\.local\s*$/!p' \
                > "${tmp_dir_path}/${output_file}"

        unset input_file
        unset output_file
        return 0
}


update_SortDomains()
{
        input_file="${1}"
        output_file="${2}"

        # Sort the domains by alphabet and also remove duplicates
        sort "${tmp_dir_path}/${input_file}" -f -u -o "${tmp_dir_path}/${output_file}"

        unset input_file
        unset output_file
        return 0
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

                while read -r domain; do

                        if [ "${use_partial_matching}" = "true" ]; then
                                # Filter out domains from whitelist, also for sub-domains
                                sed -i "/\.*${domain}$/d" "${tmp_dir_path}/applied-whitelist"
                        elif [ "${use_partial_matching}" = "false" ]; then
                                # Filter out domains from whitelist, ignoring sub-domains
                                sed -i "/\s\+${domain}$/d" "${tmp_dir_path}/applied-whitelist"
                        else
                                printf "%bWrong use_partial_matching set, either set it to 'true' or 'false'.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                                remove_ErrorCleanUp
                                exit 127
                        fi

                done < "${tmp_dir_path}/whitelist-sorted"

                cp "${tmp_dir_path}/applied-whitelist" "${tmp_dir_path}/cache"
        fi

        return 0
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

        return 0
}


update_IsCacheEmpty()
{
        if [ ! -s "${tmp_dir_path}/cache" ]; then
                printf "%bNothing to apply.\n" "${prefix_warning}" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi

        return 0
}


update_PreBuildHostsFile()
{
        {
                # Replace @...@ with the path to the backup hosts
                sed "s|#@.\+#@|${hosts_file_backup_path}|g" "${script_dir_path}/bin/components/hosts_header"

                echo ""

                # Add hosts.original
                cat "${hosts_file_backup_path}" \
                        || echo "${prefix}You may want to add your hostname to ${hosts_file_path}" 1>&2

                echo ""

                # Add hosts_title
                cat "${script_dir_path}/bin/components/hosts_title"
        } > "${tmp_dir_path}/hosts"

        return 0
}


update_BuildHostsFile()
{
        {
                echo ""

                # Add the fetched ad-domains to the hosts file
                cat "${tmp_dir_path}/cache"

                echo ""

                # Add the hosts_header to the hosts file in the temporary folder, filter out the line with @ and replace with hosts_file_backup_path
                sed "s|#@.\+#@|${hosts_file_backup_path}|g" "${script_dir_path}/bin/components/hosts_header"
        } >> "${tmp_dir_path}/hosts"

        return 0
}


update_ApplyHostsFile()
{
        echo "${prefix}Applying new hosts file ..."

        # Replace systems hosts file with the modified version
        cp "${tmp_dir_path}/hosts" "${hosts_file_path}" \
                || {
                        printf "%b" "${prefix_fatal}Couldn't apply hosts file. Aborting.${prefix_reset}\n" 1>&2
                        remove_ErrorCleanUp
                        exit 126
                }

        printf "%bSuccessfully applied new hosts file with %d blocked domains.%b\n" "${prefix_info}" "$(wc -l < "${tmp_dir_path}/cache")" "${prefix_reset}"

        return 0
}


update()
{
        printf "%bUpdating %s ...%b\n" "${prefix_title}" "${hosts_file_path}" "${prefix_reset}"

        update_CheckBackupExist
        update_CreateTmpDir
        update_ReadBlackList
        update_ReadWhiteList

        if update_ReadSourceList; then
                update_FetchSources
                update_FilterDomains "fetched" "fetched-filtered"
                update_SortDomains "fetched-filtered" "fetched-sorted"

                cp "${tmp_dir_path}/fetched-sorted" "${tmp_dir_path}/cache"
        else
                # Create empty cache file for the ad-domains.
                printf "" >> "${tmp_dir_path}/cache"
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
                        printf "%bWrong primary_list set in adsorber.conf. Choose either 'whitelist' or 'blacklist'%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        remove_ErrorCleanUp
                        exit 127
                        ;;
        esac

        update_IsCacheEmpty
        update_PreBuildHostsFile
        update_BuildHostsFile
        update_ApplyHostsFile
        remove_CleanUp

        return 0
}
