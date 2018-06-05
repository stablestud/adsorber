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
# prefix                '  ' (two spaces)               src/lib/colours.sh
# prefix_input          '  ' (two spaces)               src/lib/colours.sh
# prefix_fatal          '\033[0;91mE '                  src/lib/colours.sh
# prefix_reset          \033[0m                         src/lib/colours.sh
# prefix_warning        '- '                            src/lib/colours.sh
# systemd_dir_path      /etc/systemd/system             src/lib/config.sh, adsorber.conf

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-------  ---function defined in:---
# remove_ErrorCleanUp  src/lib/remove.sh

# shellcheck disable=SC2154

systemdSetup()
{
        # Check if the variable systemd_dir_path is valid, if not abort and call error clean-up function
        if [ ! -d "${systemd_dir_path}" ]; then
                printf "%bWrong systemd_dir_path set. Can't access: %s.%b\\n" \
			"${prefix_fatal}" "${systemd_dir_path}" "${prefix_reset}" 1>&2

                echo "${prefix}Is Systemd installed? If not use Cron instead."
                remove_ErrorCleanUp
                exit 126
        fi

        # Remove systemd service if already present
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then
                echo "${prefix}Removing previous Systemd service ..."
                if ! systemdRemove; then
			printf "%bSomething failed at updating the Systemd service, aborting ...%b" "${prefix_fatal}" "${prefix_reset}" 1>&2
			remove_ErrorCleanUp;
			exit 1;
		fi
        fi

        echo "${prefix}Setting up ${frequency} Systemd service ..."

        # Replace the @ place holder line with the location of adsorber and copy
        # the service to the systemd directory ( /etc/sytemd/system/adsorber.service )
        sed "s|#@\\/some\\/path\\/adsorber update@#$|${executable_dir_path}\\/adsorber update|g" "${library_dir_path}/systemd/adsorber.service" \
		| sed "s/#@frequency@#/${frequency}/g" \
		 > "${systemd_dir_path}/adsorber.service"

        # Copy the systemd timer to /etc/systemd/system/adsorber.timer, timer is the clock that triggers adsorber.service
	sed "s/#@frequency@#/${frequency}/g" "${library_dir_path}/systemd/adsorber.timer" \
		> "${systemd_dir_path}/adsorber.timer"

        chmod u=rwx,g=rx,o=rx "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"
        chown root:root "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"

        # Enable the systemd service and enable it to start at boot-up
        systemctl daemon-reload 2>/dev/null \
                && systemctl enable adsorber.timer 2>/dev/null

	if ! systemctl start adsorber.timer 2>/dev/null; then
		# Systemd couldn't be run, probably it's a systemd-less system like Gentoo
		printf "%bCouldn't start systemd service.%b\\n" "${prefix_fatal}" "${prefix_reset}" 1>&2
		echo "${prefix}Is Systemd installed? If not use Cron instead."
		systemdRemove
		remove_ErrorCleanUp
		exit 126
	fi

	# Make known that we have setup the systemd service in this run,
	# if we fail now, systemd will be also removed (see remove_ErrorCleanUp)
	readonly setup_scheduler="systemd"

        echo "${prefix}Initialized Systemd service ..."
}


systemdPromptFrequency()
{
	if [ -z "${frequency}" ]; then 
		printf "%bHow often should the service run? [(h)ourly/(d)aily/(W)eekly/(m)onthly/(q)uarterly]: " "${prefix_input}"
		read -r _input_frequency

		case "${_input_frequency}" in
			[Hh] | [Hh][Oo][Uu][Rr] | [Hh][Oo][Uu][Rr][Ll][Yy] )
				readonly frequency="hourly"
				;;
			[Dd] | [Dd][Aa][Yy] | [Dd][Aa][Ii][Ll][Yy] )
				readonly frequency="daily"
				;;
			[Ww] | "" | [Ww][Ee][Ee][Kk] | [Ww][Ee][Ee][Kk][Ll][Yy] )
				readonly frequency="weekly"
				;;
			[Mm] | [Mm][Oo][Nn][Tt][Hh] | [Mm][Oo][Nn][Tt][Hh][Ll][Yy] )
				readonly frequency="monthly"
				;;
			[Yy] | [Yy][Ee][Aa][Rr] | [Yy][Ee][Aa][Rr][Ll][Yy] | \
			[Aa] | [Aa][Nn][Nn][Uu][Aa][Ll] | [Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] )
				readonly frequency="yearly"
				;;
			[Qq] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr] | [Qq][Uu][Aa][Rr][Tt][Ee][Rr][Ll][Yy] )
				readonly frequency="quarterly"
				;;
			[Ss] | [Ss][Ee][Mm][Ii] | [Ss][Ee][Mm][Ii][Aa][Nn][Nn][Uu][Aa][Ll][Ll][Yy] )
				readonly frequency="semiannually"
				;;
			* )
				echo "${prefix_warning}Frequency '${_input_frequency}' not understood.${prefix_reset}" 1>&2
				systemdPromptFrequency
				;;
		esac
		
		unset _input_frequency
	fi
}


systemdRemove()
{
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then

                # Disable timer and add "${prefix}" to the output stream, to format it so it can fit the Adsorber 'style'
                systemctl stop adsorber.timer 2>/dev/null
                systemctl disable adsorber.timer 2>/dev/null \

                # Disable service
                systemctl stop adsorber.service 2>/dev/null 1>&2
                systemctl disable adsorber.service 2>/dev/null 1>&2 # This service is not enabled by default

                # Remove leftover service files.
                rm "${systemd_dir_path}/adsorber.timer" "${systemd_dir_path}/adsorber.service" 2>/dev/null 1>&2 \
                        || {
                                printf "%bCouldn't remove Systemd service files at %s%b\\n." \
					"${prefix_fatal}" "${systemd_dir_path}" "${prefix_reset}" 1>&2

                                return 1
                        }

                # Let systemd know that files have been changed
                systemctl daemon-reload 2>/dev/null

                echo "${prefix}Removed Adsorber's Systemd service."
        else
                echo "${prefix}Systemd service not installed. Skipping ..."
        fi
}


systemd()
{
	systemdPromptFrequency
	systemdSetup
}
