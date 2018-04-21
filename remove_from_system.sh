#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Define where the executable 'adsorber' is.
readonly executable_path="/usr/local/bin/adsorber"

# Define where the other executable are.
readonly library_dir_path="/usr/local/lib/adsorber/"

# Define the location of adsorbers shareable data (e.g. default config files...).
readonly shareable_dir_path="/usr/local/share/adsorber/"

# Define the location of the config files for adsorber.
readonly config_dir_path="/usr/local/etc/adsorber/"

# Define the location of the log file. Not in use (yet).
#readonly log_file_path="/var/log/adsorber.log"

# Resolve script directory.
readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

## Following variables are only used when Adsorber's own removal activity failed
## and are used to remove Adsorber in the 'hard' way. Please change according to
## your system configuration
readonly hosts_file_path="/etc/hosts"
readonly hosts_file_backup_path="/etc/hosts.original"
readonly systemd_timer_path="/etc/systemd/system/adsorber.timer"
readonly systemd_service_path="/etc/systemd/system/adsorber.service"
readonly crontab_path="/etc/cron.weekly/80adsorber"
readonly tmp_dir_path="/tmp/adsorber"

echo "Current script location: ${script_dir_path}"

echo "Going to remove files from:"
echo " - main exectuable:   ${executable_path}"
echo " - other executables: ${library_dir_path}"
echo " - configuration:     ${config_dir_path}"
echo " - miscellaneous:     ${shareable_dir_path}"

printHelp() {
	echo
	echo "Help screen of remove_from_system.sh"

	exit 0
}

prompt="${1}"

if [ "${prompt}" = "help" ] || [ "${prompt}" = "h" ] || [ "${prompt}" = "-h" ] || [ "${prompt}" = "--help" ]; then
	printHelp
fi

# Prompt user if sure about to remove Adsorber from the system
if [ -z "${prompt}" ]; then
        printf "Are you sure you want to remove Adsorber from the system? [(Y)es/(N)o]: "
        read -r prompt
fi

case "${prompt}" in
        -[Yy] | --[Yy][Ee][Ss] | [Yy] | [Yy][Ee][Ss] )
                :
                ;;
        * )
                echo "Removal from the system has been cancelled."
                exit 1
                ;;
esac

# Check if user is root, if not exit.
if [ "$(id -g)" -ne 0 ]; then
        echo "You need to be root to remove Adsorber from the system." 1>&2
        exit 126
fi

echo

echo "Running 'adsorber remove -y' ..."
( adsorber remove -x ) \
        || {
                echo
                printf "\\033[0;93mSomething went wrong at running Adsorber's own removal action.\\nDoing it the hard way ...\\n\\033[0m"
                echo "Maybe Adsorber has been removed already?"

                # Doing it the hard way .., removing everything manually
                rm "${systemd_timer_path}" 2>/dev/null && echo "Removed ${systemd_timer_path}"
                rm "${systemd_timer_path}" 2>/dev/null && echo "Removed ${systemd_timer_path}"
                rm "${systemd_service_path}" 2>/dev/null && echo "Removed ${systemd_service_path}"
                systemctl daemon-reload 2>/dev/null && echo "Reloaded systemctl daemon"
                rm "${crontab_path}" 2>/dev/null && echo "Removed ${crontab_path}"
                rm -r "${tmp_dir_path}" 2>/dev/null && echo "Removed ${tmp_dir_path}"

                if [ -f "${hosts_file_backup_path}" ]; then
                        echo "Backup of hosts file found at ${hosts_file_backup_path}"
                        echo "Relacing current hosts file with backup ..."
                        mv "${hosts_file_backup_path}" "${hosts_file_path}"
                fi
        }

echo

# Remove placed files from the specified locations
rm -r "${executable_path}" 2>/dev/null && echo "Removed ${executable_path}"
rm -r "${library_dir_path}" 2>/dev/null && echo "Cleaned ${library_dir_path}"
rm -r "${shareable_dir_path}" 2>/dev/null && echo "Cleaned ${shareable_dir_path}"
rm -r "${config_dir_path}" 2>/dev/null && echo "Cleaned ${config_dir_path}"

echo "Clearing adsorber from shell cache ..."
# Remove the adsorber command from cache/hashtable
if command -v hash 1>/dev/null; then
        # Works in bash
        hash -d adsorber 2>/dev/null
elif command -v rehash 1>/dev/null; then
        # For csh and zsh shells
        rehash
else
        # Should work for all shells
        export PATH="${PATH}"
fi

echo

echo "Done. Adsorber has been removed from the system."
