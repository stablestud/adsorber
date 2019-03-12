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
# frequency             null (not set)                  src/bin/adsorber
# library_dir_path      ${executable_dir_path}/../lib   src/bin/adsorber
# log_file_path         /var/log/adsorber.log           src/bin/adsorber
# prefix                '  ' (two spaces)               src/lib/colours.sh
# prefix_input          '  ' (two spaces)               src/lib/colours.sh
# prefix_fatal          '\033[0;91mE '                  src/lib/colours.sh
# prefix_reset          \033[0m                         src/lib/colours.sh
# prefix_warning        '- '                            src/lib/colours.sh
# version		0.5.0 or similiar		src/bin/adsorber

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# --function:--  ---function defined in:---
# errorCleanUp   src/lib/cleanup.sh

# shellcheck disable=SC2154

crontabSetup()
{
        echo "${prefix}Setting up ${frequency_string} Cronjob ..."

        # Check if crontabs directory variable is correctly set, if not abort and call the error clean-up function
        if [ ! -d "${crontab_dir_path}" ]; then
                printf "%bWrong frequency set. Can't access: %s.%b\\n" \
			"${prefix_fatal}" "${crontab_dir_path}" "${prefix_reset}" 1>&2

                echo "${prefix}Is a Cron service installed? If not use Systemd if possible."
                errorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with the location of adsorber in 80adsorber
        # and copy and manipulate the content to crontabs directory
        sed "s|#@version@#|${version}|g" "${library_dir_path}/cron/default-cronjob.sh" \
                | sed "s|#@/some/path/adsorber update@#|\"${executable_dir_path}/adsorber\" update --noformatting|g" \
		| sed "s|#@frequency@#|${frequency_string}|g" \
		| sed "s|#@/some/path/to/logfile@#|${log_file_path}|g" \
                > "${crontab_dir_path}/80adsorber"

        chmod u=rwx,g=rx,o=rx "${crontab_dir_path}/80adsorber"
        chown root:root "${crontab_dir_path}/80adsorber"

        # Make known that we have setup the Crontab in this run,
        # if we fail now, Crontab will be also removed (see errorCleanUp)
        readonly setup_scheduler="cronjob"
}


crontabPromptFrequency()
{
	if [ -z "${frequency}" ]; then
		_used_input="true"
		printf "%bHow often should the scheduler run? [(h)ourly/(d)aily/(W)eekly/(m)onthly]: " "${prefix_input}"
		read -r frequency
	fi

	case "${frequency}" in
		[Hh] | [Hh][Oo][Uu][Rr] | [Hh][Oo][Uu][Rr][Ll][Yy] )
			readonly frequency_string="hourly"
			readonly crontab_dir_path="/etc/cron.hourly/"
			;;
		[Dd] | [Dd][Aa][Yy] | [Dd][Aa][Ii][Ll][Yy] )
			readonly frequency_string="daily"
			readonly crontab_dir_path="/etc/cron.daily/"
			;;
		[Ww] | "" | [Ww][Ee][Ee][Kk] | [Ww][Ee][Ee][Kk][Ll][Yy] )
			readonly frequency_string="weekly"
			readonly crontab_dir_path="/etc/cron.weekly/"
			;;
		[Mm] | [Mm][Oo][Nn][Tt][Hh] | [Mm][Oo][Nn][Tt][Hh][Ll][Yy] )
			readonly frequency_string="monthly"
			readonly crontab_dir_path="/etc/cron.monthly/"
			;;
		[Yy] | [Yy][Ee][Aa][Rr] | [Yy][Ee][Aa][Rr][Ll][Yy] | \
		[Aa] | [Aa][Nn][Nn][Uu][Aa][Ll] | [Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] | \
		[Qq] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr][Ll][Yy] | \
		[Ss] | [Ss][Ee][Mm][Ii] | [Ss][Ee][Mm][Ii][Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] )
			if [ "${_used_input}" = "true" ]; then
				echo "${prefix_warning}This frequency is only available with Systemd." 1>&2
				unset frequency
				crontabPromptFrequency
			else
				printf "%bThis frequency is only available with Systemd.%b\\n" \
					"${prefix_fatal}" "${prefix_reset}" 1>&2
				errorCleanUp
				exit 1
			fi
			;;
		* )
			if [ "${_used_input}" = "true" ]; then
				echo "${prefix_warning}Frequency '${frequency}' not understood." 1>&2
				unset frequency
				crontabPromptFrequency
			else
				printf "%bFrequency '%s' not understood.%b\\n" \
					"${prefix_fatal}" "${frequency}" "${prefix_reset}" 1>&2
				errorCleanUp
				exit 1
			fi
			;;
	esac

	unset _used_input
}


crontabRemove()
{
        if [ -f "/etc/cron.hourly/80adsorber" ] \
	|| [ -f "/etc/cron.daily/80adsorber" ] \
	|| [ -f "/etc/cron.weekly/80adsorber" ] \
	|| [ -f "/etc/cron.monthly/80adsorber" ]; then
                # Remove the crontab from /etc/cron.* or other if specified
                rm /etc/cron.?????*/80adsorber \
                        || {
                                printf "%bCouldn't remove Crontab %s\\n." \
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
	crontabPromptFrequency \
		&& crontabSetup
}
