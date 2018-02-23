#!/bin/bash

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------------   ---default value:----   ---defined in:--------------
# CRONTAB_DIR_PATH            /etc/cron.weekly        bin/config.sh, adsorber.conf
# COLOUR_RESET                \033[0m                 bin/colours.sh
# HOSTS_FILE_PATH             /etc/hosts              bin/config.sh, adsorber.conf
# HOSTS_FILE_BACKUP_PATH      /etc/hosts.original     bin/config.sh, adsorber.conf
# PREFIX                      '  ' (two spaces)       bin/colours.sh
# PREFIX_INPUT                '  ' (two spaces)       bin/colours.sh
# PREFIX_FATAL                '\033[0;91mE '          bin/colours.sh
# PREFIX_TITLE                \033[1;37m              bin/colours.sh
# PREFIX_WARNING              '- '                    bin/colours.sh
# REPLY_TO_PROMPT             Null (not set)          bin/install.sh, adsorber.sh
# REPLY_TO_SCHEDULER_PROMPT   Null (not set)          bin/install.sh, adsorber.sh
# SCRIPT_DIR_PATH             script root directory   adsorber.sh
#   (e.g., /home/user/Downloads/adsorber)
# SYSTEMD_DIR_PATH            /etc/systemd/system     bin/config.sh, adsorber.conf

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----  ---function defined in:---
# cleanUp            bin/remove.sh
# errorCleanUp       bin/remove.sh
# remove::Systemd      bin/remove.sh


install::BackupHostsFile()
{
        if [ ! -f "${HOSTS_FILE_BACKUP_PATH}" ]; then
                cp "${HOSTS_FILE_PATH}" "${HOSTS_FILE_BACKUP_PATH}" \
                        && echo "${PREFIX}Successfully created backup of ${HOSTS_FILE_PATH} to ${HOSTS_FILE_BACKUP_PATH}."
                readonly BACKEDUP="true"
        else
                echo "${PREFIX}Backup already exist, no need to backup."
        fi

        return 0
}


install::Cronjob()
{
        echo "${PREFIX}Installing cronjob ..."

        if [ ! -d "${CRONTAB_DIR_PATH}" ]; then
                echo -e "${PREFIX_FATAL}Wrong CRONTAB_DIR_PATH set. Can't access: ${CRONTAB_DIR_PATH}.${COLOUR_RESET}" 1>&2
                errorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with SCRIPT_DIR_PATH and copy the content to cron's directory
        sed "s|^#@.\+#@$|${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SCRIPT_DIR_PATH}/bin/cron/80adsorber" > "${CRONTAB_DIR_PATH}/80adsorber"
        chmod u=rwx,g=rx,o=rx "${CRONTAB_DIR_PATH}/80adsorber"

        readonly INSTALLED_SCHEDULER="cronjob"

        return 0
}


install::Systemd()
{

        if [ ! -d "${SYSTEMD_DIR_PATH}" ]; then
                echo -e "${PREFIX_FATAL}Wrong SYSTEMD_DIR_PATH set. Can't access: ${SYSTEMD_DIR_PATH}.${COLOUR_RESET}" 1>&2
                errorCleanUp
                exit 126
        fi

        # Remove systemd service if already installed (requires remove.sh)
        if [ -f "${SYSTEMD_DIR_PATH}/adsorber.service" ] || [ -f "${SYSTEMD_DIR_PATH}/adsorber.timer" ]; then
                echo "${PREFIX}Removing previous installed systemd service ..."
                remove::Systemd
        fi

        echo "${PREFIX}Installing systemd service ..."

        # Replace the @ place holder line with SCRIPT_DIR_PATH and copy to its systemd directory
        sed "s|^#@ExecStart.\+#@$|ExecStart=${SCRIPT_DIR_PATH}\/adsorber\.sh update|g" "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.service" > "${SYSTEMD_DIR_PATH}/adsorber.service"
        cp "${SCRIPT_DIR_PATH}/bin/systemd/adsorber.timer" "${SYSTEMD_DIR_PATH}/adsorber.timer"

        chmod u=rwx,g=rx,o=rx "${SYSTEMD_DIR_PATH}/adsorber.service" "${SYSTEMD_DIR_PATH}/adsorber.timer"

        # Enable the systemd service
        systemctl daemon-reload \
                && systemctl enable adsorber.timer | printf "%s" "${PREFIX}" \
                && systemctl start adsorber.timer || echo -e "${PREFIX_WARNING}Couldn't start systemd service." 1>&2

        readonly INSTALLED_SCHEDULER="systemd"

        return 0
}


install::Prompt()
{
        if [ -z "${REPLY_TO_PROMPT}" ]; then
                read -r -p "${PREFIX_INPUT}Do you really want to install Adsorber? [Y/n]: " REPLY_TO_PROMPT
        fi

        case "${REPLY_TO_PROMPT}" in
                [Yy] | [Yy][Ee][Ss] )
                        return 0
                        ;;
                * )
                        echo -e "${PREFIX_WARNING}Installation cancelled." 1>&2
                        errorCleanUp
                        exit 130
                        ;;
        esac

        return 0
}


install::PromptScheduler()
{
        if [ -z "${REPLY_TO_SCHEDULER_PROMPT}" ]; then
                read -r -p "${PREFIX_INPUT}What scheduler should be used to update hosts file automatically? [(S)ystemd/(C)ron/(N)one]: " REPLY_TO_SCHEDULER_PROMPT
        fi

        case "${REPLY_TO_SCHEDULER_PROMPT}" in
                [Ss] | [Ss]ystemd | [Ss][Yy][Ss] )
                        install::Systemd
                        ;;
                [Cc] | [Cc]ron | [Cc]ron[Jj]ob | [Cc]ron[Tt]ab )
                        install::Cronjob
                        ;;
                * )
                        echo "${PREFIX}Skipping scheduler creation ..."
                        ;;
        esac

        return 0
}


install()
{
        echo -e "${PREFIX_TITLE}Installing Adsorber ...${COLOUR_RESET}"
        install::Prompt
        install::BackupHostsFile
        install::PromptScheduler

        return 0
}
