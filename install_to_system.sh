#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Define where the executable 'adsorber' file will be placed, it must be found
# when you type 'adsorber' into your console
readonly executable_path="/usr/local/bin/adsorber"

# Define where the other executables will be placed.
readonly library_dir_path="/usr/local/lib/adsorber/"

# Define the location of adsorbers shareable data (e.g. default config files...).
readonly shareable_dir_path="/usr/local/share/adsorber/"

# Define the location of the config files for adsorber.
readonly config_dir_path="/usr/local/etc/adsorber/"

# Define the location of the log file. Not in use (yet).
#readonly log_file_path="/var/log/adsorber.log"

# Resolve script directory.
readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

echo "Current script location: ${script_dir_path}"

echo "Going to place files to:"
echo " - main exectuable:   ${executable_path}"
echo " - other executables: ${library_dir_path}"
echo " - configuration:     ${config_dir_path}"
echo " - miscellaneous:     ${shareable_dir_path}"

printHelp() {
        echo
        echo "Help screen of install_to_system.sh"
        exit 0
}

prompt="${1}"

if [ "${prompt}" = "help" ] || [ "${prompt}" = "h" ] || [ "${prompt}" = "-h" ] || [ "${prompt}" = "--help" ]; then
        printHelp
fi

if [ -z "${prompt}" ]; then
        printf "Are you sure you want to install Adsorber into the system? [(Y)es/(N)o]: "
        read -r prompt
fi

case "${prompt}" in
        -[Yy] | --[Yy][Ee][Ss] | [Yy] | [Yy][Ee][Ss] )
                :
                ;;
        * )
                echo "Installation to the system has been cancelled."
                exit 1
                ;;
esac

# Check if user is root, if not exit.
if [ "$(id -g)" -ne 0 ]; then
        echo "You need to be root to install Adsorber into the system." 1>&2
        exit 126
fi

echo ""


##[ Main exectuable ]###########################################################
echo "Placing main executable to ${executable_path}"

mkdir -p "$(dirname ${executable_path})"

# Replacing the path to the libraries with the ones defined above.
sed "s|^readonly library_dir_path=\"\${executable_dir_path}/\\.\\./lib/\"$|readonly library_dir_path=\"${library_dir_path}\"|g" "${script_dir_path}/src/bin/adsorber" \
        | sed "s|^readonly shareable_dir_path=\"\${executable_dir_path}/\\.\\./share/\"$|readonly shareable_dir_path=\"${shareable_dir_path}\"|g" \
        | sed "s|^readonly config_dir_path=\"\${executable_dir_path}/\\.\\./\\.\\./\"$|readonly config_dir_path=\"${config_dir_path}\"|g" \
        > "${executable_path}"

chmod u=rwx,g=rx,o=rx "${executable_path}" \
        || {
                printf "Couldn't set permissions for %s" "${executable_path}"
        }
chown root:root "${executable_path}" \
        || {
                printf "Couldn't set ownership fo %s" "${executable_path}"
        }


##[ Libaries ]##################################################################
echo "Placing other executables to ${library_dir_path}"

mkdir -p "${library_dir_path}"

cp -r "${script_dir_path}/src/lib/." "${library_dir_path}"

chmod -R u=rwx,g=rx,o=rx "${library_dir_path}" \
        || {
                printf "Couldn't set permissions for %s" "${library_dir_path}"
        }
chown -R root:root "${library_dir_path}" \
        || {
                printf "Couldn't set ownership of %s" "${library_dir_path}"
        }

##[ Shareables ]################################################################
echo "Placing miscellaneous to ${shareable_dir_path}"

mkdir -p "${shareable_dir_path}"

cp -r "${script_dir_path}/src/share/." "${shareable_dir_path}"

chmod -R u=rwx,g=rx,o=rx "${shareable_dir_path}" \
        || {
                printf "Couldn't set permissions for %s" "${shareable_dir_path}"
        }
chown -R root:root "${shareable_dir_path}" \
        || {
                printf "Couldn't set ownership of %s" "${shareable_dir_path}"
        }

##[ Config files ]##############################################################
echo "Placing config files to ${config_dir_path}"

mkdir -p "${config_dir_path}"

cp "${script_dir_path}/src/share/default/default-adsorber.conf" "${config_dir_path}/adsorber.conf"
cp "${script_dir_path}/src/share/default/default-blacklist" "${config_dir_path}/blacklist"
cp "${script_dir_path}/src/share/default/default-whitelist" "${config_dir_path}/whitelist"
cp "${script_dir_path}/src/share/default/default-sources.list" "${config_dir_path}/sources.list"

chmod -R u=rwx,g=rx,o=rx "${config_dir_path}" \
        || {
                printf "Couldn't set permissions for %s" "${config_dir_path}"
        }
chown -R root:root "${config_dir_path}" \
        || {
                printf "Couldn't set ownership of %s" "${config_dir_path}"
        }



#echo "Installation into the system completed."
#echo "Running Adsorber..."
#echo ""

echo

## We don't run Adsorber after installation yet
#adsorber install \
#        || {
#                printf "\033[0;93mAdsorber was installed on your system, however something went wrong at\\n"
#                printf "running it.\\n"
#                printf "If a proxy server is in use, please change the config file\\n"
#                printf "(${config_dir_path}/adsorber.conf) to the appropriate proxy server.\\n\033[0m"
#                echo "Run 'adsorber install' to try again."
#        }

echo "Installation completed. You may want to run 'adsorber install'"
echo "You can now delete this folder."
