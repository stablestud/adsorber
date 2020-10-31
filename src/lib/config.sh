#!/bin/sh

# Author:     stablestud
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Variable naming:
# under_score        - used for global variables which are accessible between functions.
# _extra_under_score - used for local function variables. Should be unset afterwards.
#          (Note the underscore in the beginning of _extra_under_score!)

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:------   ---default value:---------------  ---declared in:-------
# config_dir_path      ${executable_dir_path}/../../     src/bin/adsorber
# debug                false                             src/bin/adsorber
# options              every parameter but first         src/bin/adsorber
# operations           the first parameter               src/bin/adsorber
# prefix               '  ' (two spaces)                 src/lib/colours.sh
# prefix_reset         \033[0m                           src/lib/colours.sh
# prefix_title         \033[1;37m                        src/lib/colours.sh
# prefix_warning       '- '                              src/lib/colours.sh
# shareable_dir_path   ${executable_dir_path}/../share/  src/bin/adsorber
# tmp_dir_path         /tmp/adsorber                     src/bin/adsorber
# version              0.2.2 or similar                  src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# --function:--  --function defined in:--
# errorCleanUp   src/lib/cleanup.sh

# shellcheck disable=SC2154

config_CreateTmpDir()
{
        # Create a temporary folder in which Adsorber can manipulate files
        # without distracting the environment
        if [ ! -d "${tmp_dir_path}" ]; then
                mkdir "${tmp_dir_path}"
        else
                echo "${prefix}Removing previous tmp folder ..."
                rm -rf "${tmp_dir_path}"
                mkdir "${tmp_dir_path}"
        fi
}


config_CopySourceList()
{
        # Create sources.list if not found. Adsorber need sources.list to know from where to fetch hosts domains from
        if [ ! -f "${config_dir_path}/sources.list" ] || [ ! -s "${config_dir_path}/sources.list" ]; then
                cp "${shareable_dir_path}/default/default-sources.list" "${config_dir_path}/sources.list" \
                        && echo "${prefix_warning}Created sources.list - to add new host sources edit this file."
        fi
}


config_CopyWhiteList()
{
        # Create whitelist if not found, used to whitelist domains which should be excluded from blocking
        if [ ! -f "${config_dir_path}/whitelist" ] || [ ! -s "${config_dir_path}/whitelist" ]; then
                cp "${shareable_dir_path}/default/default-whitelist" "${config_dir_path}/whitelist" \
                        && echo "${prefix_warning}Created whitelist - to allow specific domains edit this file."
        fi
}


config_CopyBlackList()
{
        # Create blacklist if not found, used to explicitly block domains
        if [ ! -f "${config_dir_path}/blacklist" ] || [ ! -s "${config_dir_path}/blacklist" ]; then
                cp "${shareable_dir_path}/default/default-blacklist" "${config_dir_path}/blacklist" \
                        && echo "${prefix_warning}Created blacklist - to block additional domains edit this file."
        fi
}


config_CopyConfig()
{
        # Can't proceed without a config file. Creating a new one if not found
        if [ ! -s "${config_dir_path}/adsorber.conf" ] || [ ! -f "${config_dir_path}/adsorber.conf" ]; then
                printf "%bNo config file found. Creating default.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                echo "${prefix_warning}Please re-run the command to continue."

                sed "s|^#@ Config file for Adsorber v.*@#$|## Config file for Adsorber v${version}|g" "${shareable_dir_path}/default/default-adsorber.conf" \
                        > "${config_dir_path}/adsorber.conf"

                exit 126
        fi
}


config_FilterConfig()
{
        # Remove comments, etc., to be able to read the config file
        cp "${config_dir_path}/adsorber.conf" "${tmp_dir_path}/config" \
                || {
                        printf "%bCouldn't process config file.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                        errorCleanUp
                        exit 126
                }

        {
                # Only keep the important configuration lines
                sed -n "/^primary_list=/p" "${tmp_dir_path}/config"
                sed -n "/^use_partial_matching=/p" "${tmp_dir_path}/config"
                sed -n "/^ignore_download_error=/p" "${tmp_dir_path}/config"
                sed -n "/^http_proxy=/p" "${tmp_dir_path}/config"
                sed -n "/^https_proxy=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_path=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_backup_path=/p" "${tmp_dir_path}/config"
                sed -n "/^hosts_file_previous_enable=/p" "${tmp_dir_path}/config"
                sed -n "/^systemd_dir_path=/p" "${tmp_dir_path}/config"
        } > "${tmp_dir_path}/config-filtered"
}


config_ReadConfig()
{
        # Read config file line by line
        # Check if a configuration has been already defined, if yes,
        # print out a error message and keep the previous defined value
        while read -r _line; do
                case "${_line}" in
                        primary_list=* )
                                if [ -z "${primary_list}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'primary_list', using the first value: ${primary_list}"
                                fi
                                ;;
                        use_partial_matching=* )
                                if [ -z "${use_partial_matching}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'use_partial_matching', using the first value: ${use_partial_matching}"
                                fi
                                ;;
                        ignore_download_error=* )
                                if [ -z "${ignore_download_error}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'ignore_download_error', using the first value: ${ignore_download_error}"
                                fi
                                ;;
                        http_proxy=* )
                                if [ -z "${http_proxy_env}" ]; then
                                        # shellcheck disable=SC2163
                                        export "${_line}"
                                        export HTTP_PROXY="${http_proxy}"
                                elif [ -n "${http_proxy_env}" ]; then
                                        export "${_line}"
                                        if [ -z "${http_proxy}" ]; then
                                                export http_proxy="${http_proxy_env}"
                                                export HTTP_PROXY="${http_proxy_env}"
                                        else
                                                export HTTP_PROXY="${http_proxy}"
                                                echo "${prefix}Config HTTP proxy '${http_proxy}' overwrites environmental HTTP proxy '${http_proxy_env}'"
                                        fi
                                fi
                                ;;
                        https_proxy=* )
                                if [ -z "${https_proxy_env}" ]; then
                                        # shellcheck disable=SC2163
                                        export "${_line}"
                                        export HTTPS_PROXY="${https_proxy}"
                                elif [ -n "${https_proxy_env}" ]; then
                                        export "${_line}"
                                        if [ -z "${https_proxy}" ]; then
                                                export https_proxy="${https_proxy_env}"
                                                export HTTPS_PROXY="${https_proxy_env}"
                                        else
                                                export HTTPS_PROXY="${https_proxy}"
                                                echo "${prefix}Config HTTPS proxy '${https_proxy}' overwrites environmental HTTPS proxy '${https_proxy_env}'"
                                        fi
                                fi
                                ;;
                        hosts_file_path=* )
                                if [ -z "${hosts_file_path}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'hosts_file_path', using the first value: ${hosts_file_path}"
                                fi
                                ;;
                        hosts_file_backup_path=* )
                                if [ -z "${hosts_file_backup_path}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'hosts_file_backup_path', using the first value: ${hosts_file_backup_path}"
                                fi
                                ;;
                        hosts_file_previous_enable=* )
                                if [ -z "${hosts_file_previous_enable}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'hosts_file_previous_enable', using the first value: ${hosts_file_previous_enable}"
                                fi
                                ;;
                        systemd_dir_path=* )
                                if [ -z "${systemd_dir_path}" ]; then
                                        readonly "${_line}"
                                else
                                        echo "${prefix_warning}Duplicate configuration for 'systemd_dir_path', using the first value: ${systemd_dir_path}"
                                fi
                                ;;
                        * )
                                # This should never be reached, as the config
                                # file was filtered by config_FilterConfig and
                                # should not contain any unknown lines
                                printf "%bThis is scary: I extracted %s from the config file, however I shouldn't be able to.%b\\n" \
                                        "${prefix_fatal}" "${_line}" "${prefix_reset}"

                                echo "Please report this error with your config file to https://github.com/stablestud/adsorber"
                                errorCleanUp
                                exit 1
                                ;;
                esac
        done < "${tmp_dir_path}/config-filtered"

        unset _line
}


config_CheckEnvVariables()
{
        if [ -n "${HTTP_PROXY}" ]; then
                http_proxy_env="${HTTP_PROXY}"
        elif [ -n "${http_proxy}" ]; then
                http_proxy_env="${http_proxy}"
        fi

        if [ -n "${HTTPS_PROXY}" ]; then
                https_proxy_env="${HTTPS_PROXY}"
        elif [ -n "${https_proxy}" ]; then
                https_proxy_env="${https_proxy}"
        fi
}


config_IsVariableSet()
{
        # These configurations are not mandatory needed by Adsorber, thus
        # if any of them were not defined, Adsorber will use the default value
        if [ -z "${primary_list}" ]; then
                readonly primary_list="blacklist"
                printf "%bprimary_list not set in adsorber.conf. Using default value: ${primary_list}\\n" \
                        "${prefix_warning}" 1>&2

        fi

        if [ -z "${use_partial_matching}" ]; then
                readonly use_partial_matching="true"
                printf "%buse_partial_matching not set in adsorber.conf. Using default value: ${use_partial_matching}\\n" \
                        "${prefix_warning}" 1>&2
        fi

        if [ -z "${ignore_download_error}" ]; then
                readonly ignore_download_error="false"
                printf "%bignore_download_error not set in adsorber.conf. Using default value: ${ignore_download_error}\\n" \
                        "${prefix_warning}" 1>&2
        fi

        if [ -z "${hosts_file_previous_enable}" ]; then
                readonly hosts_file_previous_enable="true"
                printf "%bhosts_file_previous_enable not set in adsorber.conf. Using default value: ${hosts_file_previous_enable}\\n" \
                        "${prefix_warning}" 1>&2
        fi

        # Check if essential configurations were set in the config file
        # if not abort, and call error clean-up function
        if [ -z "${hosts_file_path}" ] || [ -z "${hosts_file_backup_path}" ] \
        || [ -z "${systemd_dir_path}" ]; then
                printf "%bMissing setting(s) in adsorber.conf%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                printf "%bPlease delete adsorber.conf in %s and run 'adsorber setup' to create a new config file.\\n" \
                        "${prefix_warning}" "${config_dir_path}" 1>&2

                errorCleanUp
                exit 127
        fi
}


config_IsVariableValid()
{
        # Check if the defined values for the configurations are valid e.g.
        # are readable and understood by Adsorber, if not print error message
        # and abort with the error clean-up function

        if [ "${primary_list}" != "blacklist" ] && [ "${primary_list}" != "whitelist" ]; then
                printf "%bInvalid 'primary_list' set in adsorber.conf. Choose either 'blacklist' or 'whitelist'%b\\n" \
                        "${prefix_fatal}" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ "${use_partial_matching}" != "true" ] && [ "${use_partial_matching}" != "false" ]; then
                printf "%bInvalid 'use_partial_matching' set in adsorber.conf. Possible values: 'true' or 'false'%b\\n" \
                        "${prefix_fatal}" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ "${ignore_download_error}" != "true" ] && [ "${ignore_download_error}" != "false" ]; then
                printf "%bInvalid 'ignore_download_error' set in adsorber.conf. Possible values: 'true' or 'false'%b\\n" \
                        "${prefix_fatal}" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ ! -f "${hosts_file_path}" ] || [ ! -w "${hosts_file_path}" ]; then
                printf "%bInvalid 'hosts_file_path' set in adsorber.conf. Can't write/access: %s%b\\n" \
                        "${prefix_fatal}" "${hosts_file_path}" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ ! -d "$(dirname "${hosts_file_backup_path}")" ] || [ ! -w "$(dirname "${hosts_file_backup_path}")" ]; then
                printf "%bInvalid 'hosts_file_backup_path' set in adsorber.conf. Can't access: %s%b\\n" \
                        "${prefix_fatal}" "$(dirname "${hosts_file_backup_path}")" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ "${hosts_file_previous_enable}" != "true" ] && [ "${hosts_file_previous_enable}" != "false" ]; then
                printf "%bInvalid 'hosts_file_previous_enable' set in adsorber.conf. Possible values: 'true' or 'false'%b\\n" \
                        "${prefix_fatal}" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        if [ ! -d "$(dirname "${tmp_dir_path}")" ] || [ ! -w "$(dirname "${tmp_dir_path}")" ]; then
                printf "%bInvalid 'tmp_dir_path' set in adsorber.conf. Can't access: %s%b\\n" \
                        "${prefix_fatal}" "$(dirname "${tmp_dir_path}")" "${prefix_reset}" 1>&2

                invalidVariable="true"
        fi

        # If one or more values were invalid exit with error message
        if [ "${invalidVariable}" = "true" ]; then
                errorCleanUp
                exit 126
        fi
}


config_PrintVariables()
{
        # Used for debugging and is only run when 'debug' is set to 'true' in src/bin/adsorber
        echo "  Invoked with: ${0} ${operation} ${options}"
        echo "  - primary_list: ${primary_list}"
        echo "  - use_partial_matching: ${use_partial_matching}"
        echo "  - ignore_download_error: ${ignore_download_error}"
        echo "  - http_proxy: ${http_proxy}"
        echo "  - https_proxy: ${https_proxy}"
        echo "  - hosts_file_path: ${hosts_file_path}"
        echo "  - hosts_file_backup_path: ${hosts_file_backup_path}"
        echo "  - hosts_file_previous_enable: ${hosts_file_previous_enable}"
        echo "  - systemd_dir_path: ${systemd_dir_path}"
        echo "  - tmp_dir_path: ${tmp_dir_path}"
        echo "  - cache_dir_path: ${cache_dir_path}"
        echo "  - executable_dir_path: ${executable_dir_path}"
        echo "  - library_dir_path: ${library_dir_path}"
        echo "  - shareable_dir_path: ${shareable_dir_path}"
        echo "  - config_dir_path: ${config_dir_path}"
        echo "  - use_formatting: ${use_formatting}"
}


# Main function for calling config related tasks
config()
{
        printf "%bReading configuration ...%b\\n" "${prefix_title}" "${prefix_reset}"
        config_CreateTmpDir
        config_CopySourceList
        config_CopyWhiteList
        config_CopyBlackList
        config_CopyConfig
        config_FilterConfig
        config_CheckEnvVariables
        config_ReadConfig
        config_IsVariableSet
        config_IsVariableValid
}
