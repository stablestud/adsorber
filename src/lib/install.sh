#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------------   ---default value:----   ---defined in:--------------
# crontab_dir_path            /etc/cron.weekly        bin/config.sh, adsorber.conf
# hosts_file_path             /etc/hosts              bin/config.sh, adsorber.conf
# hosts_file_backup_path      /etc/hosts.original     bin/config.sh, adsorber.conf
# prefix                      '  ' (two spaces)       bin/colours.sh
# prefix_input                '  ' (two spaces)       bin/colours.sh
# prefix_fatal                '\033[0;91mE '          bin/colours.sh
# prefix_reset                \033[0m                 bin/colours.sh
# prefix_title                \033[1;37m              bin/colours.sh
# prefix_warning              '- '                    bin/colours.sh
# reply_to_prompt             Null (not set)          bin/install.sh, adsorber.sh
# reply_to_scheduler_prompt   Null (not set)          bin/install.sh, adsorber.sh
# binary_dir_path             script root directory   adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# systemd_dir_path            /etc/systemd/system     bin/config.sh, adsorber.conf
# version                     0.2.2 or similar        adsorber.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_ErrorCleanUp  bin/remove.sh
# Systemd_remove       bin/remove.sh


install_BackupHostsFile()
{
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
        if [ -z "${reply_to_scheduler_prompt}" ]; then
                printf "%bWhat scheduler should be used to update the host file automatically? [(S)ystemd/(C)ron/(N)one]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_scheduler_prompt
        fi

        case "${reply_to_scheduler_prompt}" in
                [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
                        Systemd_install
                        ;;
                [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
                        Cronjob_install
                        ;;
                * )
                        echo "${prefix}Skipping scheduler creation ..."
                        ;;
        esac

        return 0
}


install_command()
{

        return 0
}


install()
{
        printf "%bInstalling Adsorber ...%b\n" "${prefix_title}" "${prefix_reset}"
        install_Prompt
        install_BackupHostsFile
        install_PromptScheduler

        return 0
}
