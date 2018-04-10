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
# executable_dir_path   the root dir of the script      src/bin/adsorber
# library_dir_path      ${executable_dir_path}/../lib   src/bin/adsorber
# prefix                '  ' (two spaces)               src/lib/colours.sh
# prefix_fatal          '\033[0;91mE '                  src/lib/colours.sh
# prefix_reset          \033[0m                         src/lib/colours.sh
# prefix_warning        '- '                            src/lib/colours.sh
# systemd_dir_path      /etc/systemd/system             src/lib/config.sh, adsorber.conf

# The following functions are defined in different files.
# If you run this file independently following functions need to be emulated:
# ---function:-----     ---function defined in:---
# remove_ErrorCleanUp   src/lib/remove.sh


Systemd_install()
{
        # Check if the variable systemd_dir_path is valid, if not abort and call error clean-up function
        if [ ! -d "${systemd_dir_path}" ]; then
                printf "%bWrong systemd_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${systemd_dir_path}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 126
        fi

        # Remove systemd service if already installed
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then
                echo "${prefix}Removing previously installed systemd services ..."
                Systemd_remove
        fi

        echo "${prefix}Installing systemd service ..."

        # Replace the @ place holder line with the location of adsorber and copy
        # the service to the systemd directory ( /etc/sytemd/system/adsorber.service )
        sed "s|^#@ExecStart=\/some\/path\/adsorber update@#$|ExecStart=${executable_dir_path}\/adsorber update|g" "${library_dir_path}/systemd/adsorber.service" \
                > "${systemd_dir_path}/adsorber.service"
        # Copy the systemd timer to /etc/systemd/system/adsorber.timer, timer is the clock that triggers adsorber.service
        cp "${library_dir_path}/systemd/adsorber.timer" "${systemd_dir_path}/adsorber.timer"

        chmod u=rwx,g=rx,o=rx "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"
        chown root:root "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"

        # Enable the systemd service and enable it to start at boot up
        systemctl daemon-reload \
                && systemctl enable adsorber.timer | printf "%s" "${prefix}" \
                && systemctl start adsorber.timer || printf "%bCouldn't start systemd service.\n" "${prefix_warning}" 1>&2

        # Make known that we have installed the systemd service in this run,
        # if we fail now, systemd will be also removed (see remove_ErrorCleanUp)
        readonly installed_scheduler="systemd"

        return 0
}


Systemd_remove()
{
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then

                 # Disable timer and add "${prefix}" to the output stream, to format it so it can fit the Adsorber 'style'
                systemctl stop adsorber.timer 2>/dev/null
                systemctl disable adsorber.timer | ( printf "%b" "${prefix}" && cat )

                # Disable service
                systemctl stop adsorber.service 2>/dev/null 1>&2
                systemctl disable adsorber.service 2>/dev/null 1>&2 # This service is not enabled by default

                # Remove leftover service files.
                rm "${systemd_dir_path}/adsorber.timer" "${systemd_dir_path}/adsorber.service" \
                        || {
                                printf "%bCouldn't remove systemd service files at %s\n." "${prefix_warning}" "${systemd_dir_path}" 1>&2
                                return 1
                        }

                # Let systemd know that files have been changed
                systemctl daemon-reload
        else
                echo "${prefix}Systemd service not installed. Skipping ..."
        fi

        return 0
}
