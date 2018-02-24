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
# prefix_reset            \033[0m                 bin/colours.sh
# prefix_title                \033[1;37m              bin/colours.sh
# prefix_warning              '- '                    bin/colours.sh
# reply_to_prompt             Null (not set)          bin/install.sh, adsorber.sh
# reply_to_scheduler_prompt   Null (not set)          bin/install.sh, adsorber.sh
# script_dir_path             script root directory   adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# systemd_dir_path            /etc/systemd/system     bin/config.sh, adsorber.conf

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_ErrorCleanUp  bin/remove.sh
# remove_Systemd       bin/remove.sh


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


install_Cronjob()
{
        echo "${prefix}Installing cronjob ..."

        if [ ! -d "${crontab_dir_path}" ]; then
                printf "%bWrong crontab_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${crontab_dir_path}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with script_dir_path and copy the content to cron's directory
        sed "s|^#@.\+#@$|${script_dir_path}\/adsorber\.sh update|g" "${script_dir_path}/bin/cron/80adsorber" > "${crontab_dir_path}/80adsorber"
        chmod u=rwx,g=rx,o=rx "${crontab_dir_path}/80adsorber"

        readonly installed_scheduler="cronjob"

        return 0
}


install_Systemd()
{

        if [ ! -d "${systemd_dir_path}" ]; then
                printf "%bWrong systemd_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${systemd_dir_path}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 126
        fi

        # Remove systemd service if already installed (requires remove.sh)
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then
                echo "${prefix}Removing previous installed systemd service ..."
                remove_Systemd
        fi

        echo "${prefix}Installing systemd service ..."

        # Replace the @ place holder line with script_dir_path and copy to its systemd directory
        sed "s|^#@ExecStart.\+#@$|ExecStart=${script_dir_path}\/adsorber\.sh update|g" "${script_dir_path}/bin/systemd/adsorber.service" > "${systemd_dir_path}/adsorber.service"
        cp "${script_dir_path}/bin/systemd/adsorber.timer" "${systemd_dir_path}/adsorber.timer"

        chmod u=rwx,g=rx,o=rx "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"

        # Enable the systemd service
        systemctl daemon-reload \
                && systemctl enable adsorber.timer | printf "%s" "${prefix}" \
                && systemctl start adsorber.timer || printf "%bCouldn't start systemd service.\n" "${prefix_warning}" 1>&2

        readonly installed_scheduler="systemd"

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
                printf "%bWhat scheduler should be used to update hosts file automatically? [(S)ystemd/(C)ron/(N)one]: %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_scheduler_prompt
        fi

        case "${reply_to_scheduler_prompt}" in
                [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
                        install_Systemd
                        ;;
                [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
                        install_Cronjob
                        ;;
                * )
                        echo "${prefix}Skipping scheduler creation ..."
                        ;;
        esac

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
