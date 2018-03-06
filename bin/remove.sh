#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------     ---default value:----   ---defined in:--------------
# backedup                Null (not set)          bin/install.sh
# crontab_dir_path        /etc/cron.weekly        bin/config.sh, adsorber.conf
# hosts_file_backup_path  /etc/hosts.original     bin/config.sh, adsorber.conf
# installed_scheduler     Null (not set)          bin/install.sh
# prefix                  '  ' (two spaces)       bin/colours.sh
# prefix_input            '  ' (two spaces)       bin/colours.sh
# prefix_reset            \033[0m                 bin/colours.sh
# prefix_title            \033[1;37m              bin/colours.sh
# prefix_warning          '- '                    bin/colours.sh
# reply_to_prompt         Null (not set)          bin/install.sh, adsorber.sh
# systemd_dir_path        /etc/systemd/system     bin/config.sh, adsorber.conf


remove_ErrorCleanUp()
{
        printf "%bCleaning up ...\n" "${prefix_warning}"

        # Remove scheduler if installed in the same run
        case "${installed_scheduler}" in
                cronjob )
                        remove_Cronjob
                        ;;
                systemd )
                        remove_Systemd
                        ;;
        esac

        if [ "${backedup}" = "true" ]; then
                rm "${hosts_file_backup_path}"
        fi

        if [ -d "${tmp_dir_path}" ]; then
                rm -r "${tmp_dir_path}"
        fi
        
        return 0
}


remove_CleanUp()
{
        echo "${prefix}Cleaning up ..."

        rm -r "${tmp_dir_path}"
        return 0
}


remove_Systemd()
{
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then

                systemctl stop adsorber.timer 2>/dev/null
                systemctl disable adsorber.timer | ( printf "%b" "${prefix}" && cat ) # Add "${prefix} to the output stream"
                systemctl stop adsorber.service 2>/dev/null 1>&2
                systemctl disable adsorber.service 2>/dev/null 1>&2 # The service is not enabled by default

                rm "${systemd_dir_path}/adsorber.timer" "${systemd_dir_path}/adsorber.service" \
                        || {
                                printf "%bCouldn't remove systemd service files at %s\n." "${prefix_warning}" "${systemd_dir_path}" 1>&2
                                return 1
                        }

                systemctl daemon-reload
        else
                echo "${prefix}Systemd service not installed. Skipping ..."
        fi

        return 0
}


remove_Cronjob()
{
        if [ -f "${crontab_dir_path}/80adsorber" ]; then
                rm "${crontab_dir_path}/80adsorber" \
                        && echo "${prefix}Removed Adsorber's cronjob."
        else
                echo "${prefix}Cronjob not installed. Skipping ..."
        fi

        return 0
}


remove_Prompt()
{
        if [ -z "${reply_to_prompt}" ]; then
                printf "%bDo you really want to remove Adsorber? [Y/n] %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_prompt
        fi

        case "${reply_to_prompt}" in
                [Yy] | [Yy][Ee][Ss] )
                        : # Do nothing
                        ;;
                * )
                        printf "%bRemove cancelled.\n" "${prefix_warning}" 1>&2
                        remove_ErrorCleanUp
                        exit 130
                        ;;
        esac

        return 0
}


remove_HostsFile()
{
        if [ -f "${hosts_file_backup_path}" ]; then
                mv "${hosts_file_backup_path}" "${hosts_file_path}" \
                        && echo "${prefix}Successfully restored ${hosts_file_path}"
        else
                printf "%bCan not restore hosts file. Original hosts file does not exist.%b\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                echo "${prefix}Maybe already removed?" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi

        return 0
}


remove_PreviousHostsFile()
{
        if [ -f "${hosts_file_previous_path}" ]; then
                rm "${hosts_file_previous_path}" \
                        && echo "${prefix}Removed previous hosts file."
        else
                echo "${prefix}Previous hosts file not installed. Ignoring ..."
        fi
        
        return 0
}


remove()
{
        printf "%bRemoving Adsorber ...%b\n"  "${prefix_title}" "${prefix_reset}"
        remove_Prompt
        remove_Systemd
        remove_Cronjob
        remove_HostsFile
        remove_PreviousHostsFile
        remove_CleanUp

        return 0
}
