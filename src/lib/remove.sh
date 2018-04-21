#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Variable naming:
# under_score        - used for global variables which are accessible between functions.
# _extra_under_score - used for local function variables. Should be unset afterwards.
#          (Note the underscore in the beginning of _extra_under_score!)

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:-------     ---default value:---  ---defined in:------------------
# backedup                Null (not set)        src/lib/install.sh
# hosts_file_path         /etc/hosts            src/lib/config.sh, adsorber.conf
# hosts_file_backup_path  /etc/hosts.original   src/lib/config.sh, adsorber.conf
# installed_scheduler     Null (not set)        src/lib/systemd/systemd.sh, src/lib/cron/cron.sh
# prefix                  '  ' (two spaces)     src/lib/colours.sh
# prefix_fatal            '\033[0;91mE '        src/lib/colours.sh
# prefix_input            '  ' (two spaces)     src/lib/colours.sh
# prefix_reset            \033[0m               src/lib/colours.sh
# prefix_title            \033[1;37m            src/lib/colours.sh
# prefix_warning          '- '                  src/lib/colours.sh
# reply_to_prompt         Null (not set)        src/bin/adsorber
# tmp_dir_path            /tmp/adsorber         src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----  ---function defined in:---
# systemdRemove      src/lib/systemd/systemd.sh
# crontabRemove      src/lib/cron/cron.sh

# shellcheck disable=SC2154

# This function cleans-up all changed files if Adsorber runs into a problem
remove_ErrorCleanUp()
{
        printf "%bCleaning up ...\\n" "${prefix_warning}"

        # Remove scheduler if it was installed in the same run
        case "${installed_scheduler}" in
                cronjob )
                        crontabRemove
                        ;;
                systemd )
                        systemdRemove
                        ;;
        esac

        # Remove backup if backed-up in the same run
        if [ "${backedup}" = "true" ]; then
                echo "${prefix_warning}Removed backup as the installation failed."
                rm "${hosts_file_backup_path}"
        fi

        # Remove /tmp/adsorber directory
        if [ -d "${tmp_dir_path}" ]; then
                rm -r "${tmp_dir_path}"
        fi

        return 0
}


# Normal clean-up function
remove_CleanUp()
{
        echo "${prefix}Cleaning up ..."

        # Remove the /tmp/adsorber directory
        rm -r "${tmp_dir_path}"

        return 0
}


remove_Prompt()
{
        # Ask if the user is sure about to remove Adsorber
        if [ -z "${reply_to_prompt}" ]; then
                printf "%bDo you really want to remove Adsorber? [Y/n] %b" "${prefix_input}" "${prefix_reset}"
                read -r reply_to_prompt
        fi

        case "${reply_to_prompt}" in
                [Yy] | [Yy][Ee][Ss] )
                        : # Do nothing
                        ;;
                * )
                        # If other input then Yes, abort and call error clean-up function
                        printf "%bRemoval cancelled.\\n" "${prefix_warning}" 1>&2
                        remove_ErrorCleanUp
                        exit 130
                        ;;
        esac

        return 0
}


remove_HostsFile()
{
        # Moves the original hosts file (backed-up at /etc/hosts.original)
        # to /etc/hosts, replacing the current one
        if [ -f "${hosts_file_backup_path}" ]; then
                mv "${hosts_file_backup_path}" "${hosts_file_path}" \
                        && echo "${prefix}Successfully restored ${hosts_file_path}"
        else
                # If /etc/hosts.original was not found, abort and call the error clean-up function
                printf "%bCan not restore hosts file. Original hosts file does not exist.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
                echo "${prefix}Maybe already removed?" 1>&2
                remove_ErrorCleanUp
                exit 1
        fi

        return 0
}


remove_PreviousHostsFile()
{
        # If found, remove /etc/hosts.previous
        if [ -f "${hosts_file_previous_path}" ]; then
                rm "${hosts_file_previous_path}" \
                        && echo "${prefix}Removed previous hosts file."
        else
                echo "${prefix}Previous hosts file does not exist. Ignoring ..."
        fi

        return 0
}


# Main function of remove.sh
remove()
{
        printf "%bRemoving Adsorber ...%b\\n"  "${prefix_title}" "${prefix_reset}"
        remove_Prompt
        systemdRemove
        crontabRemove
        remove_HostsFile
        remove_PreviousHostsFile
        remove_CleanUp

        return 0
}
