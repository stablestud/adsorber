#!/bin/sh

# Author:     stablestud
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:--------   ---default value:------------   ----declared in:------------
# prefix                 '  ' (two spaces)               bin/colours.sh
# prefix_reset           \033[0m                         bin/colours.sh
# prefix_title           \033[1;37m                      bin/colours.sh
# prefix_warning         '- '                            bin/colours.sh
# primary_list           blacklist                       bin/config.sh, adsorber.conf
# binary_dir_path        script root directory           adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# tmp_dir_path           /tmp/adsorber                   adsorber.sh
# use_partial_matching   true                            bin/config.sh, adsorber.conf
# version                0.2.2 or similar                adsorber.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_ErrorCleanUp   bin/remove.sh


config_CreateTmpDir()
{
        if [ ! -d "${tmp_dir_path}" ]; then
                mkdir "${tmp_dir_path}"
        else
                echo "${prefix}Removing previous tmp folder ..."
                rm -rf "${tmp_dir_path}"
                mkdir "${tmp_dir_path}"
        fi

        return 0
}


config_CopySourceList()
{
        if [ ! -f "${config_dir_path}/sources.list" ] || [ ! -s "${config_dir_path}/sources.list" ]; then
                cp "${shareable_dir_path}/default/default-sources.list" "${config_dir_path}/sources.list" \
                        && echo "${prefix_warning}Created sources.list: to add new host sources edit this file."
                chown root:root -R "${config_dir_path}/sources.list"
                chmod u=rwx,g=rx,o=r -R "${config_dir_path}/sources.list"
        fi

        return 0
}


config_CopyWhiteList()
{
        if [ ! -f "${config_dir_path}/whitelist" ] || [ ! -s "${config_dir_path}/whitelist" ]; then
                cp "${shareable_dir_path}/default/default-whitelist" "${config_dir_path}/whitelist" \
                        && echo "${prefix_warning}Created whitelist: to allow specific domains edit this file."
                chown root:root -R "${config_dir_path}/whitelist"
                chmod u=rwx,g=rx,o=r -R "${config_dir_path}/whitelist"
        fi

        return 0
}


config_CopyBlackList()
{
        if [ ! -f "${config_dir_path}/blacklist" ] || [ ! -s "${config_dir_path}/blacklist" ]; then
                cp "${shareable_dir_path}/default/default-blacklist" "${config_dir_path}/blacklist" \
                        && echo "${prefix_warning}Created blacklist: to block additional domains edit this file."
                chown root:root -R "${config_dir_path}/blacklist"
                chmod u=rwx,g=rx,o=r -R "${config_dir_path}/blacklist"
        fi

        return 0
}


config_CopyConfig()
{
        if [ ! -s "${config_dir_path}/adsorber.conf" ] || [ ! -f "${config_dir_path}/adsorber.conf" ]; then
                printf "%bNo config file found. Creating default.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                echo "${prefix_warning}Please re-run the command to continue."
                sed "s|@.*|# Config file for Adsorber v${version}|g" "${shareable_dir_path}/default/default-adsorber.conf" > "${config_dir_path}/adsorber.conf"

                chown root:root -R "${config_dir_path}/adsorber.conf"
                chmod u=rwx,g=rx,o=r -R "${config_dir_path}/adsorber.conf"
                exit 126
        fi

        return 0
}


config_FilterConfig()
{
        cp "${config_dir_path}/adsorber.conf" "${tmp_dir_path}/config" \
                || {
                        printf "%bCouldn't process config file.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        remove_ErrorCleanUp
                        exit 126
                }

        {
                sed -n "/^primary_list=/p" "${tmp_dir_path}/config"
                sed -n "/^use_partial_matching=/p" "${tmp_dir_path}/config"
                sed -n "/^ignore_download_error=/p" "${tmp_dir_path}/config"
                sed -n "/^http_proxy=/p" "${tmp_dir_path}/config"
                sed -n "/^https_proxy=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_path=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_backup_path=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_previous_enable=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_previous_path=/p" "${tmp_dir_path}/config"
                sed -n "/^crontab_dir_path=/p" "${tmp_dir_path}/config"
                sed -n "/^systemd_dir_path=/p" "${tmp_dir_path}/config"
        } > "${tmp_dir_path}/config-filtered"

        return 0
}


config_ReadConfig()
{
        while read -r line; do
                case "${line}" in
                        http_proxy* )
                                readonly "set_${line}"
                                if [ -n "$set_http_proxy" ]; then
                                        export "${line}"
                                fi
                                ;;
                        https_proxy* )
                                readonly "set_${line}"
                                if [ -n "$set_https_proxy" ]; then
                                        export "${line}"
                                fi
                                ;;
                        * )
                                readonly "${line}"
                                ;;
                esac
        done < "${tmp_dir_path}/config-filtered"

        return 0
}


config_IsVariableSet()
{
        if [ -z "${hosts_file_path}" ] || [ -z "${hosts_file_backup_path}" ] || [ -z "${crontab_dir_path}" ] || [ -z "${systemd_dir_path}" ] || [ -z "${hosts_file_previous_path}" ] || [ -z "${hosts_file_previous_enable}" ]; then
                printf "%bMissing setting(s) in adsorber.conf.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                printf "%bPlease delete adsorber.conf and run '%s install' to create a new config file.%b\n" "${prefix_fatal}" "${0}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 127
        fi

        if [ -z "${primary_list}" ]; then
                printf "%bprimary_list not set in adsorber.conf. Using default value: blacklist\n" "${prefix_warning}" 1>&2
                readonly primary_list="blacklist"
        fi

        if [ -z "${use_partial_matching}" ]; then
                printf "%buse_partial_matching not set in adsorber.conf. Using default value: true\n" "${prefix_warning}" 1>&2
                readonly use_partial_matching="true"
        fi

        if [ -z "${ignore_download_error}" ]; then
                printf "%bignore_download_error not set in adsorber.conf. Using default value: false\n" "${prefix_warning}" 1>&2
                readonly ignore_download_error="false"
        fi

        return 0
}


config_IsVariableValid()
{
        # TODO: Check if proxy is valid ( with ping )

        if [ "${primary_list}" != "blacklist" ] && [ "${primary_list}" != "whitelist" ]; then
                printf "%bWrong 'primary_list' set in adsorber.conf. Choose either 'blacklist' or 'whitelist'%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ "${use_partial_matching}" != "true" ] && [ "${use_partial_matching}" != "false" ]; then
                printf "%bWrong 'use_partial_matching' set in adsorber.conf. Possible options: 'true' or 'false'%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ "${ignore_download_error}" != "true" ] && [ "${ignore_download_error}" != "false" ]; then
                printf "%bWrong 'ignore_download_error' set in adsorber.conf. Possible options: 'true' or 'false'%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ ! -f "${hosts_file_path}" ]; then
                printf "%bWrong 'hosts_file_path' set in adsorber.conf. Can't access: %s%b\n" "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ ! -d "$(dirname "${hosts_file_backup_path}")" ]; then
                printf "%bWrong 'hosts_file_backup_path' set in adsorber.conf. Can't access: %s%b\n" "${prefix_fatal}" "$(dirname "${hosts_file_backup_path}")" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ "${hosts_file_previous_enable}" != "true" ] && [ "${hosts_file_previous_enable}" != "false" ]; then
                printf "%bWrong 'hosts_file_previous_enable' set in adsorber.conf. Possible options: 'true' or 'false'%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ ! -d "$(dirname "${hosts_file_previous_path}")" ]; then
                printf "%bWrong 'hosts_file_previous_path' set in adsorber.conf. Can't access: %s%b\n" "${prefix_fatal}" "$(dirname "${hosts_file_previous_path}")" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ ! -d "$(dirname "${tmp_dir_path}")" ]; then
                printf "%bWrong 'tmp_dir_path' set in adsorber.conf. Can't access: %s%b\n" "${prefix_fatal}" "$(dirname "${tmp_dir_path}")" "${prefix_reset}" 1>&2
                wrongVariable="true"
        fi

        if [ -n "${wrongVariable}" ]; then      # When wrongVariable is set then ...
                remove_ErrorCleanUp
                exit 126
        fi

        return 0
}


config_PrintVariables()
{
        echo "  Invoked with: ${0} ${operation} ${options}"
        echo "  - primary_list: ${primary_list}"
        echo "  - use_partial_matching: ${use_partial_matching}"
        echo "  - ignore_download_error: ${ignore_download_error}"
        echo "  - http_proxy: ${http_proxy}"
        echo "  - https_proxy: ${https_proxy}"
        echo "  - hosts_file_path: ${hosts_file_path}"
        echo "  - hosts_file_backup_path: ${hosts_file_backup_path}"
        echo "  - hosts_file_previous_enable: ${hosts_file_previous_enable}"
        echo "  - hosts_file_previous_path: ${hosts_file_previous_path}"
        echo "  - crontab_dir_path: ${crontab_dir_path}"
        echo "  - systemd_dir_path: ${systemd_dir_path}"
        echo "  - tmp_dir_path: ${tmp_dir_path}"
        echo "  - executable_dir_path: ${executable_dir_path}"
        echo "  - library_dir_path: ${library_dir_path}"
        echo "  - shareable_dir_path: ${shareable_dir_path}"
        echo "  - config_dir_path: ${config_dir_path}"

        return 0
}


config()
{
        printf "%b" "${prefix_title}Reading configuration ... ${prefix_reset}\n"
        config_CreateTmpDir
        config_CopySourceList
        config_CopyWhiteList
        config_CopyBlackList
        config_CopyConfig
        config_FilterConfig
        config_ReadConfig
        config_IsVariableSet
        config_IsVariableValid
        #config_PrintVariables # used for debugging

        return 0
}
