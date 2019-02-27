#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# This file can run independently, no need to download the full repository to
# remove an existing installation.
# Note: only run this file if Adsorber was placed onto the system (via place_files_onto_system.sh)
# and not if it was used with portable-mode (portable_adsorber.sh)

##########[ Edit to fit your system ]###########################################

# Define where the executable 'adsorber' is.
readonly executable_path="/usr/local/bin/adsorber"

# Define where the other executables are.
readonly library_dir_path="/usr/local/lib/adsorber/"

# Define the location of adsorbers shareable data (e.g. default config files...).
readonly shareable_dir_path="/usr/local/share/adsorber/"

# Define the location of the config files for adsorber.
readonly config_dir_path="/usr/local/etc/adsorber/"

## Following variables are only used when Adsorber's own removal activity failed
## and are used to remove Adsorber manually. Please change according to
## your system configuration
readonly hosts_file_path="/etc/hosts"
readonly hosts_file_backup_path="/etc/hosts.original"
readonly hosts_file_previous_path="/etc/hosts.previous"
readonly systemd_dir_path="/etc/systemd/system"
readonly tmp_dir_path="/tmp/adsorber"

##########[ End of configuration ]##############################################

# Resolve script directory.
readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

printLocation()
{
	echo "Going to remove files from:"
        echo " - main exectuable:   ${executable_path}"
        echo " - other executables: ${library_dir_path}"
        echo " - configuration:     ${config_dir_path}"
        echo " - miscellaneous:     ${shareable_dir_path}"

        return 0
}


printHelp()
{
        printf "\\033[4;37mremove_from_system.sh\\033[0m:\\n\\n"
        echo "   Will remove Adsorbers executables and other"
        echo "   files relevant to Adsorber from the system."
        echo
        printf "\\033[4;37mNote\\033[0m: Adsorbers own 'remove' command will not do the same action as\\n"
        echo "this script, as it will only remove the scheduler and restore the original hosts"
        echo "file but Adsorber will still be present on the system. "
        echo
        echo "Usage: ${0} [option]:"
        echo
        echo "Options:"
        echo "  -y, --yes       automatically reply the prompt with yes"
        echo "  -h, --help      show this help screen"
        echo
        printLocation

	exit 0
}


prompt="${1}"

if [ "${prompt}" = "help" ] || [ "${prompt}" = "h" ] || [ "${prompt}" = "-h" ] || [ "${prompt}" = "--help" ]; then
	printHelp
fi


#echo "Current script location: ${script_dir_path}"
#printLocation
#echo


# Prompt user if sure about to remove Adsorber from the system
if [ -z "${prompt}" ]; then
	printf "Are you sure you want to remove Adsorber from the system? [(y)es/(N)o]: "
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


# Run Adsorber's own removal, if it fails do it manually
if command -v adsorber 1>/dev/null; then
	printf "\\nRunning 'adsorber disable -y --noformatting' ...\\n\\n"
	( adsorber "disable" "-y" "--noformatting" ) \
		|| {
			echo
			printf "\\033[0;93mSomething went wrong at running Adsorber's own disable operation.\\nNo worries, I can handle it ...\\n\\033[0m"
			echo "Maybe Adsorber has been already removed ?"
			readonly _hard_way="true"
		}
else
	readonly _hard_way="true"
fi


# Doing it the hard way .., removing everything manually
if [ "${_hard_way}" = "true" ]; then
		printf "\\nTrying portable_adsorber.sh ... "

		if "${script_dir_path}/portable_adsorber.sh" "disable" "-y" "--noformatting" 2>/dev/null 1>&2; then
			printf "found\\n"
			printf "Removed successfully Adsorber\\n"
		else
			printf "no luck\\n"
			"${script_dir_path}/misc/clean.sh" 2>/dev/null 1>&2
		fi


                rm "${systemd_dir_path}/adsorber.timer" 2>/dev/null && echo "Removed ${systemd_dir_path}/adsorber.timer"
                rm "${systemd_dir_path}/adsorber.service" 2>/dev/null && echo "Removed ${systemd_dir_path}/adsorber.service"
                systemctl daemon-reload 2>/dev/null && echo "Reloaded systemctl daemon"

		# Remove all crontabs
                if [ -f "/etc/cron.hourly/80adsorber" ]; then
			rm "/etc/cron.hourly/80adsorber" 2>/dev/null \
				&& echo "Removed cronjob from /etc/cron.hourly/"
		fi

                if [ -f "/etc/cron.daily/80adsorber" ]; then
			rm "/etc/cron.daily/80adsorber" 2>/dev/null \
				&& echo "Removed cronjob from /etc/cron.daily/"
		fi

                if [ -f "/etc/cron.weekly/80adsorber" ]; then
			rm "/etc/cron.weekly/80adsorber" 2>/dev/null \
				&& echo "Removed cronjob from /etc/cron.weekly/"
		fi

                if [ -f "/etc/cron.monthly/80adsorber" ]; then
			rm "/etc/cron.monthly/80adsorber" 2>/dev/null \
				&& echo "Removed cronjob from /etc/cron.monthly/"
		fi


                rm -r "${tmp_dir_path}" 2>/dev/null && echo "Removed ${tmp_dir_path}"

                if [ -f "${hosts_file_backup_path}" ]; then
                        echo "Backup of hosts file found at ${hosts_file_backup_path}"
                        echo "Relacing current hosts file with backup ..."
                        mv "${hosts_file_backup_path}" "${hosts_file_path}"
                fi

                rm "${hosts_file_previous_path}" 2>/dev/null && echo "Removed ${hosts_file_previous_path}"
fi

echo


# Remove placed files from the specified locations
rm -r "${executable_path}" 2>/dev/null && echo "Removed ${executable_path}"
rm -r "${library_dir_path}" 2>/dev/null && echo "Cleaned ${library_dir_path}"
rm -r "${shareable_dir_path}" 2>/dev/null && echo "Cleaned ${shareable_dir_path}"
rm -r "${config_dir_path}" 2>/dev/null && echo "Cleaned ${config_dir_path}"


# Remove the adsorber command from cache/hashtable.
# Shells must be reloaded / reopened to have an effect
echo "Clearing adsorber from shell cache ..."

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
