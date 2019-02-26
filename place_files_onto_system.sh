#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

##########[ Edit to fit your system ]###########################################

# Define where the executable 'adsorber(.sh)' file will be placed, it must be
# found when you type 'adsorber' into your console
readonly executable_path="/usr/local/bin/adsorber"

# Define where the other executables will be placed.
readonly library_dir_path="/usr/local/lib/adsorber/"

# Define the location of adsorbers shareable data (e.g. default config files...).
readonly shareable_dir_path="/usr/local/share/adsorber/"

# Define the location of the config files for adsorber.
readonly config_dir_path="/usr/local/etc/adsorber/"

# Define the location of the log file. Not in use (yet).
#readonly log_file_path="/var/log/adsorber.log"

##########[ End of configuration ]##############################################

# Resolve script directory.
readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

printLocation()
{
        echo "Going to place files to:"
        echo " - main exectuable:   ${executable_path}"
        echo " - other executables: ${library_dir_path}"
        echo " - configuration:     ${config_dir_path}"
        echo " - miscellaneous:     ${shareable_dir_path}"

        return 0
}

printHelp()
{
        printf "\\033[4;37minstall_to_system.sh\\033[0m:\\n\\n"
        echo "   Will place Adsorbers executables and other"
        echo "   files relevant to Adsorber into the system."
        echo
        printf "\\033[4;37mNote\\033[0m: Adsorbers own 'setup' command will not do the same action as\\n"
        echo "this script, as it will only setup the scheduler and backup the original hosts file."
        echo "You may want to run 'adsorber setup' afterwards"
        echo
        echo "Usage: ${0} [option]:"
        echo
        echo "Options:"
        echo "  -y, --yes       automatically reply the confirmation prompt with yes"
        echo "  -h, --help      show this help screen"
        echo
        printLocation

        exit 0
}

prompt="${1}"

if [ "${prompt}" = "help" ] || [ "${prompt}" = "h" ] || [ "${prompt}" = "-h" ] || [ "${prompt}" = "--help" ]; then
        printHelp
fi

echo "Current script location: ${script_dir_path}"
printLocation
echo

if [ -z "${prompt}" ]; then
        printf "Are you sure you want to place Adsorbers files onto the system? [(y)es/(N)o]: "
        read -r prompt
fi

case "${prompt}" in
        -[Yy] | --[Yy][Ee][Ss] | [Yy] | [Yy][Ee][Ss] )
                :
                ;;
        * )
                echo "Placing files onto the system has been cancelled."
                exit 1
                ;;
esac

# Check if user is root, if not exit.
if [ "$(id -g)" -ne 0 ]; then
        echo "You need to be root to place Adsorbers files onto the system." 1>&2
        exit 126
fi

echo

##[ Main exectuable ]###########################################################
echo "Placing main executable (src/bin/adsorber) to ${executable_path}"

mkdir -p "$(dirname ${executable_path})"

# Replacing the path to the libraries with the ones defined above.
sed "s|^readonly library_dir_path=\"\${executable_dir_path}/\\.\\./lib/\"$|readonly library_dir_path=\"${library_dir_path}\"|g" "${script_dir_path}/src/bin/adsorber" \
        | sed "s|^readonly shareable_dir_path=\"\${executable_dir_path}/\\.\\./share/\"$|readonly shareable_dir_path=\"${shareable_dir_path}\"|g" \
        | sed "s|^readonly config_dir_path=\"\${executable_dir_path}/\\.\\./\\.\\./\"$|readonly config_dir_path=\"${config_dir_path}\"|g" \
        > "${executable_path}"

chmod a+x "${executable_path}"


##[ Libraries ]#################################################################
echo "Placing other executables (src/lib/*) to ${library_dir_path}"

mkdir -p "${library_dir_path}"

cp -r "${script_dir_path}/src/lib/." "${library_dir_path}"


##[ Shareables ]################################################################
echo "Placing miscellaneous (src/share/*) to ${shareable_dir_path}"

mkdir -p "${shareable_dir_path}"

cp -r "${script_dir_path}/src/share/." "${shareable_dir_path}"


##[ Config files ]##############################################################
echo "Copying config files (src/share/default/*) to ${config_dir_path}"

mkdir -p "${config_dir_path}"

cp "${script_dir_path}/src/share/default/default-adsorber.conf" "${config_dir_path}/adsorber.conf"
cp "${script_dir_path}/src/share/default/default-blacklist" "${config_dir_path}/blacklist"
cp "${script_dir_path}/src/share/default/default-whitelist" "${config_dir_path}/whitelist"
cp "${script_dir_path}/src/share/default/default-sources.list" "${config_dir_path}/sources.list"


echo
echo "Adsorber files have been successfully placed onto the system."
printf "\\033[1;37mTo start going (to setup the scheduler and to backup the hosts file) run 'adsorber setup'\\033[0m\\n"

## We don't run Adsorber after installation yet
#adsorber setup --noformatting \
#        || {
#                printf "\\n\033[0;93mAdsorber has been placed onto your system, however something went wrong at\\n"
#                printf "running it.\\n"
#                printf "If a proxy server is in use, please change the config file\\n"
#                printf "(${config_dir_path}/adsorber.conf) to the appropriate proxy server.\\n\033[0m"
#                echo "Run 'adsorber setup' to try again."
#        }
