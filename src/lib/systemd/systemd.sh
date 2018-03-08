#!/bin/sh

Systemd_install()
{

        if [ ! -d "${systemd_dir_path}" ]; then
                printf "%bWrong systemd_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${systemd_dir_path}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 126
        fi

        # Remove systemd service if already installed (requires remove.sh)
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then
                echo "${prefix}Removing previous installed systemd service ..."
                Systemd_remove
        fi

        echo "${prefix}Installing systemd service ..."

        # Replace the @ place holder line with binary_dir_path and copy to its systemd directory
        sed "s|^#@ExecStart=\/some\/path\/adsorber update@#$|ExecStart=${executable_dir_path}\/adsorber update|g" "${library_dir_path}/systemd/adsorber.service" \
                > "${systemd_dir_path}/adsorber.service"
        cp "${library_dir_path}/systemd/adsorber.timer" "${systemd_dir_path}/adsorber.timer"

        chmod u=rwx,g=rx,o=rx "${systemd_dir_path}/adsorber.service" "${systemd_dir_path}/adsorber.timer"

        # Enable the systemd service
        systemctl daemon-reload \
                && systemctl enable adsorber.timer | printf "%s" "${prefix}" \
                && systemctl start adsorber.timer || printf "%bCouldn't start systemd service.\n" "${prefix_warning}" 1>&2

        readonly installed_scheduler="systemd"

        return 0
}


Systemd_remove()
{
        if [ -f "${systemd_dir_path}/adsorber.service" ] || [ -f "${systemd_dir_path}/adsorber.timer" ]; then

                systemctl stop adsorber.timer 2>/dev/null
                systemctl disable adsorber.timer | ( printf "%b" "${prefix}" && cat ) # Add "${prefix}" to the output stream
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
