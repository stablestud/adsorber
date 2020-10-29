#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------------   ---default value:----   ---defined in:------------
# crontab_dir_path            /etc/cron.weekly        src/lib/config.sh, adsorber.conf
# hosts_file_path             /etc/hosts              src/lib/config.sh, adsorber.conf
# hosts_file_backup_path      /etc/hosts.original     src/lib/config.sh, adsorber.conf
# prefix                      '  ' (two spaces)       src/lib/colours.sh
# prefix_input                '  ' (two spaces)       src/lib/colours.sh
# prefix_reset                \033[0m                 src/lib/colours.sh
# prefix_title                \033[1;37m              src/lib/colours.sh
# prefix_warning              '- '                    src/lib/colours.sh
# reply_to_prompt             Null (not set)          src/bin/adsorber
# reply_to_scheduler_prompt   Null (not set)          src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# --function:--  ---function defined in:---
# crontab        src/lib/cron/cron.sh
# errorCleanUp   src/lib/cleanup.sh
# systemd      	 src/lib/systemd/systemd.sh

# shellcheck disable=SC2154

setup_BackupHostsFile()
{
        # Create a backup, to be able to restore to it later if neccessary
        if [ ! -f "${hosts_file_backup_path}" ]; then
                cp "${hosts_file_path}" "${hosts_file_backup_path}" \
                        && echo "${prefix}Successfully created backup of ${hosts_file_path} to ${hosts_file_backup_path}."
                readonly backedup="true"
        else
                echo "${prefix}Backup already exist, no need to backup."
        fi
}


setup_Prompt()
{
        # Ask the user if he/she is sure about to setup Adsorber
        if [ -z "${reply_to_prompt}" ]; then
                printf "%bDo you really want to setup Adsorber? [Y/n]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_prompt
        fi

        case "${reply_to_prompt}" in
                [Yy] | [Yy][Ee][Ss] | "" )
                        return 0
                        ;;
                * )
                        printf "%bSetup cancelled.\\n" "${prefix_warning}" 1>&2
                        errorCleanUp
                        exit 130
                        ;;
        esac
}


setup_PromptScheduler()
{
        # The user enters interactively what scheduler (Systemd, Cron or none)
        # should be used to update the hosts file periodically
        if [ -z "${reply_to_scheduler_prompt}" ]; then
                printf "%bWhat scheduler should be used to update the host file automatically? [(C)ron/(s)ystemd/(n)one]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_scheduler_prompt
        fi

        case "${reply_to_scheduler_prompt}" in
                [Cc] | [Cc][Rr][Oo][Nn] | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab | [Cc]ronie | "" )
                        crontab
                        ;;
                [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
                        systemd
                        ;;
                * )
                        echo "${prefix}Skipping scheduler creation ..."
                        ;;
        esac
}


# Main function when calling setup related tasks
setup()
{
        printf "%bSetting up Adsorber ...%b\\n" "${prefix_title}" "${prefix_reset}"
        setup_Prompt
        setup_BackupHostsFile
        setup_PromptScheduler
}
