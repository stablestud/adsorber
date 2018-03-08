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

# Check if user is root, if not exit.
checkRoot()
{
        if [ "$(id -g)" -ne 0 ]; then
                echo "You need to be root to install Adsorber." 1>&2
                exit 126
        fi

        return 0
}

echo "Placing executable to ${executable_dir_path}"

cp "${source_dir_path}/src/adsorber" "${executable_dir_path}/adsorber"
sed -n -i "s|^readonly library_dir_path=\"${executable_dir_path}/lib/\"$|readonly library_dir_path=\"${library_dir_path}\"|g" "${executable_dir_path}/adsorber"
sed -n -i "s|^readonly shareable_dir_path=\"${executable_dir_path}/share/\"$|readonly shareable_dir_path=\"${shareable_dir_path}\"|g" "${executable_dir_path}/adsorber"
sed -n -i "s|^readonly config_dir_path=\"${executable_dir_path}/\.\./\"$|readonly config_dir_path=\"${config_dir_path}\"|g" "${executable_dir_path}/adsorber"

echo "Placing libraries to ${library_dir_path}"

mkdir "${library_dir_path}"
cp -r "${source_dir_path}/src/lib/*" "${library_dir_path}"

echo "Placing shareables to ${shareable_dir_path}"

mkdir "${shareable_dir_path}"
cp -r "${source_dir_path}/src/share/*" "${shareable_dir_path}"

echo "Placing config files to ${config_dir_path}"

mkdir "${config_dir_path}"
cp -r "${source_dir_path}/src/share/default-adsorber.conf" "${config_dir_path}"
cp -r "${source_dir_path}/src/share/default-blacklist" "${config_dir_path}"
cp -r "${source_dir_path}/src/share/default-whitelist" "${config_dir_path}"
cp -r "${source_dir_path}/src/share/default-sources.list" "${config_dir_path}"

echo "Running Adsorber..."

adsorber install --assume-yes --systemd

echo "You can now delete this folder."
