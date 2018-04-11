#!/bin/sh

# TODO: Maybe rename install to init (initialize) because there's already an
# installation into the system (install-to-system.sh) however with a different goal

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
# ---function:-----     ---function defined in:---
# crontabInstall       src/lib/cron/cron.sh
# remove_ErrorCleanUp   src/lib/remove.sh
# systemdInstall       src/lib/systemd/systemd.sh


install_BackupHostsFile()
{
        # Create a backup, to be able to restore to it later if neccessary
        if [ ! -f "${hosts_file_backup_path}" ]; then
                cp "${hosts_file_path}" "${hosts_file_backup_path}" \
                        && echo "${prefix}Successfully created backup of ${hosts_file_path} to ${hosts_file_backup_path}."
                readonly backedup="true"
        else
                echo "${prefix}Backup already exist, no need to backup."
        fi

        return 0
}


install_Prompt()
{
        # Ask the user if he/she is sure about to install Adsorber
        if [ -z "${reply_to_prompt}" ]; then
                printf "%bDo you really want to install Adsorber? [Y/n]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_prompt
        fi

        case "${reply_to_prompt}" in
                [Yy] | [Yy][Ee][Ss] )
                        return 0
                        ;;
                * )
                        printf "%bInstallation cancelled.\n" "${prefix_warning}" 1>&2
                        remove_ErrorCleanUp
                        exit 130
                        ;;
        esac

        return 0
}


install_PromptScheduler()
{
        # The user enters interactively what scheduler (Systemd, Cron or none)
        # should be used to update the hosts file periodically
        if [ -z "${reply_to_scheduler_prompt}" ]; then
                printf "%bWhat scheduler should be used to update the host file automatically? [(S)ystemd/(C)ron/(N)one]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_scheduler_prompt
        fi

        case "${reply_to_scheduler_prompt}" in
                [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
                        systemdInstall
                        ;;
                [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
                        crontabInstall
                        ;;
                * )
                        echo "${prefix}Skipping scheduler creation ..."
                        ;;
        esac

        return 0
}


# Main function when calling installation related tasks
install()
{
        printf "%bInstalling Adsorber ...%b\n" "${prefix_title}" "${prefix_reset}"
        install_Prompt
        install_BackupHostsFile
        install_PromptScheduler

        return 0
}
