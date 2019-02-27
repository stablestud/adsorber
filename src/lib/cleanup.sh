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
# ---variable:----------  ---default value:--  ---defined in:-------------------
# backedup                Null (not set)       src/lib/setup.sh
# hosts_file_backup_path  /etc/hosts.original  src/lib/config.sh, adsorber.conf
# setup_scheduler         Null (not set)       src/lib/systemd/systemd.sh, src/lib/cron/cron.sh
# prefix                  '  ' (two spaces)    src/lib/colours.sh
# tmp_dir_path            /tmp/adsorber        src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-  ---function defined in:---
# systemdRemove  src/lib/systemd/systemd.sh
# crontabRemove  src/lib/cron/cron.sh

# shellcheck disable=SC2154

# This function cleans-up all changed files if Adsorber runs into a problem
errorCleanUp()
{
        printf "%bCleaning up ...\\n" "${prefix_warning}"

        # Remove scheduler if it was setup (created) in the same run
        case "${setup_scheduler}" in
                cronjob )
                        crontabRemove
                        ;;
                systemd )
                        systemdRemove
                        ;;
        esac

        # Remove backup if backed-up in the same run
        if [ "${backedup}" = "true" ]; then
                echo "${prefix}Removed backup as the setup failed."
                rm "${hosts_file_backup_path}"
        fi

        # Remove /tmp/adsorber directory
        if [ -d "${tmp_dir_path}" ]; then
                rm -r "${tmp_dir_path}"
        fi

        return 0
}


# Normal clean-up function
cleanUp()
{
        echo "${prefix}Cleaning up ..."

        # Remove the /tmp/adsorber directory
        rm -r "${tmp_dir_path}"

        return 0
}
