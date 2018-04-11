#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Define where the executable 'adsorber' file will be placed.
readonly executable_dir_path="/usr/local/sbin/"

# Define where the other executable will be placed.
readonly library_dir_path="/usr/local/lib/adsorber/"

# Define the location of adsorbers shareable data (e.g. default config files...).
readonly shareable_dir_path="/usr/local/share/adsorber/"

# Define the location of the config files for adsorber.
readonly config_dir_path="/usr/local/etc/adsorber/"

# Define the location of the log file. Not in use (yet).
#readonly log_file_path="/var/log/adsorber.log"

# Resolve source directory.
readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

## Following variables are only used when Adsorber's own removal activity failed
## and are used to remove Adsorber onyl in the 'hard' way. Please change according
## your system configuration
readonly systemd_timer_path="/etc/systemd/system/adsorber.timer"
readonly systemd_service_path="/etc/systemd/system/adsorber.service"
readonly crontab_path="/etc/cron.weekly/80adsorber"
readonly tmp_dir_path="/tmp/adsorber"

echo "Current script location: ${source_dir_path}"

echo "Going to check files at:"
echo " - main exectuable:   ${executable_dir_path}"
echo " - other executables: ${library_dir_path}"
echo " - configuration:     ${config_dir_path}"
echo " - miscellaneous:     ${shareable_dir_path}"

# Prompt user if sure about to remove Adsorber from the system
printf "Are you sure you want to remove Adsorber from the system? [(Y)es/(N)o]: "
read -r _prompt

case "${_prompt}" in
        [Yy] | [Yy][Ee][Ss] )
                :
                ;;
        * )
                echo "Removal from system cancelled."
                exit 1
                ;;
esac

# Check if user is root, if not exit.
if [ "$(id -g)" -ne 0 ]; then
        echo "You need to be root to remove Adsorber." 1>&2
        exit 126
fi

adsorber remove -y \
        || {
                printf "\033[0;93mSometing went wrong at running Adsorber's own removal action. Doing it the hard way...\n\033[0m"
                # Doing it the hard way .., removing everything manually
                rm "${systemd_timer_path}"
                rm "${systemd_service_path}"
                rm "${crontab_path}"
                rm -r "${tmp_dir_path}"
                # TODO restore hosts file
        }

# Remove placed files from the specified locations
rm -r "${executable_dir_path}/adsorber"
rm -r "${library_dir_path}"
rm -r "${shareable_dir_path}"
rm -r "${config_dir_path}
