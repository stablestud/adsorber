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
# ---variable:-------   ---default value:------------   ---declared in:---------
# executable_dir_path   the root dir of the script      src/bin/adsorber
# frequency             none (null)                     src/bin/adsorber
# library_dir_path      ${executable_dir_path}/../lib   src/bin/adsorber
# prefix                '  ' (two spaces)               src/lib/colours.sh
# prefix_input          '  ' (two spaces)               src/lib/colours.sh
# prefix_fatal          '\033[0;91mE '                  src/lib/colours.sh
# prefix_reset          \033[0m                         src/lib/colours.sh
# prefix_warning        '- '                            src/lib/colours.sh

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-------  ---function defined in:---
# remove_ErrorCleanUp  src/lib/remove.sh

# shellcheck disable=SC2154

crontabSetup()
{
        echo "${prefix}Setting up cronjob ..."

        # Check if crontabs directory variable is correctly set, if not abort and call the error clean-up function
        if [ ! -d "${crontab_dir_path}" ]; then
                printf "%bWrong frequency set. Can't access: %s.%b\\n" \
			"${prefix_fatal}" "${crontab_dir_path}" "${prefix_reset}" 1>&2

                echo "${prefix}Is a cron service installed? If not use systemd if possible."
                remove_ErrorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with the location of adsorber in 80adsorber
        # and copy and manipulate the content to crontabs directory
        sed "s|#@version@#|${version}|g" "${library_dir_path}/cron/80adsorber" \
                | sed "s|^#@\\/some\\/path\\/adsorber update@#$|${executable_dir_path}\\/adsorber update|g" \
                > "${crontab_dir_path}/80adsorber"

        chmod u=rwx,g=rx,o=rx "${crontab_dir_path}/80adsorber"
        chown root:root "${crontab_dir_path}/80adsorber"

        # Make known that we have setup the crontab in this run,
        # if we fail now, crontab will be also removed (see remove_ErrorCleanUp)
        readonly setup_scheduler="cronjob"
}


crontabPromptFrequency()
{
	if [ -z "${frequency}" ]; then
		printf "%bHow often should the service run? [(h)ourly/(d)aily/(W)eekly/(m)onthly]: " "${prefix_input}"
		read -r frequency
	fi

	case "${frequency}" in
		[Hh] | [Hh][Oo][Uu][Rr] | [Hh][Oo][Uu][Rr][Ll][Yy] )
			readonly crontab_dir_path="/etc/cron.hourly/"
			;;
		[Dd] | [Dd][Aa][Yy] | [Dd][Aa][Ii][Ll][Yy] )
			readonly crontab_dir_path="/etc/cron.daily/"
			;;
		[Ww] | "" | [Ww][Ee][Ee][Kk] | [Ww][Ee][Ee][Kk][Ll][Yy] )
			readonly crontab_dir_path="/etc/cron.weekly/"
			;;
		[Mm] | [Mm][Oo][Nn][Tt][Hh] | [Mm][Oo][Nn][Tt][Hh][Ll][Yy] )
			readonly crontab_dir_path="/etc/cron.monthly/"
			;;
		[Yy] | [Yy][Ee][Aa][Rr] | [Yy][Ee][Aa][Rr][Ll][Yy] | \
		[Aa] | [Aa][Nn][Nn][Uu][Aa][Ll] | [Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] | \
		[Qq] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr][Ll][Yy] | \
		[Ss] | [Ss][Ee][Mm][Ii] | [Ss][Ee][Mm][Ii][Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] )
			echo "${prefix_warning}Sorry, this frequency is only available with Systemd."
			echo "Exiting ..."
			remove_ErrorCleanUp
			exit 1
			;;
		* )
			echo "${prefix_warning}Frequency '${frequency}' not understood."
			echo "Aborting ..."
			remove_ErrorCleanUp
			exit 1
			;;
	esac
}


crontabRemove()
{
        if [ -f "${crontab_dir_path}/80adsorber" ]; then
                # Remove the crontab from /etc/cron.weekly
                rm "${crontab_dir_path}/80adsorber" \
                        || {
                                printf "%bCouldn't remove crontab %s\\n." \
					"${prefix_warning}" "${crontab_dir_path}" 1>&2

                                return 1
                        }

                echo "${prefix}Removed Adsorber's cronjob."
        else
                echo "${prefix}Cronjob not installed. Skipping ..."
        fi
}


crontab()
{
	crontabPromptFrequency
	crontabSetup
}
