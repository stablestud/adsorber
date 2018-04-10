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
# ---variable:-------   ---default value:--             ---declared in:-------------
# crontab_dir_path      /etc/cron.weekly                src/lib/config.sh, adsorber.conf
# executable_dir_path   the root dir of the script      src/bin/adsorber
# library_dir_path      ${executable_dir_path}/../lib   src/bin/adsorber
# prefix                '  ' (two spaces)               src/lib/colours.sh
# prefix_fatal          '\033[0;91mE '                  src/lib/colours.sh
# prefix_reset          \033[0m                         src/lib/colours.sh
# prefix_warning        '- '                            src/lib/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_ErrorCleanUp   src/lib/remove.sh


Cronjob_install()
{
        echo "${prefix}Installing cronjob ..."

        # Check if crontabs directory variable is correctly set, if not abort and call the error clean-up function
        if [ ! -d "${crontab_dir_path}" ]; then
                printf "%bWrong crontab_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${crontab_dir_path}" "${prefix_reset}" 1>&2
                echo "${prefix}Is a cron service installed? If not use systemd if possible."
                remove_ErrorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with the location of adsorber
        # and copy and manipulate the content to crontabs directory
        sed "s|#@version@#|${version}|g" "${library_dir_path}/cron/80adsorber" \
                | sed "s|^#@\/some\/path\/adsorber update@#$|${executable_dir_path}\/adsorber update|g" \
                > "${crontab_dir_path}/80adsorber"

        chmod u=rwx,g=rx,o=rx "${crontab_dir_path}/80adsorber"
        chown root:root "${crontab_dir_path}/80adsorber"

        # Make known that we have installed the crontab in this run,
        # if we fail now, crontab will be also removed (see remove_ErrorCleanUp)
        readonly installed_scheduler="cronjob"

        return 0
}


Cronjob_remove()
{
        if [ -f "${crontab_dir_path}/80adsorber" ]; then
                # Remove the crontab from /etc/cron.weekly
                rm "${crontab_dir_path}/80adsorber" \
                        || {
                                printf "%bCouldn't remove crontab %s\n." "${prefix_warning}" "${crontab_dir_path}" 1>&2
                                return 1
                        }

                echo "${prefix}Removed Adsorber's cronjob."
        else
                echo "${prefix}Cronjob not installed. Skipping ..."
        fi

        return 0
}
