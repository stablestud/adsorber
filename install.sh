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

# Resolve installation directory
# Get the path where this file is located.
readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

# Check if user is root, if not exit.
checkRoot()
{
        if [ "$(id -g)" -ne 0 ]; then
                echo "To install Adsorber you must be root." 1>&2
                exit 126
        fi

        return 0
}

echo "Placing executable to ${executable_dir_path}"

cp

echo "Placing libraries to ${library_dir_path}"

echo "Placing shareables to ${shareable_dir_path}"

echo "Placing config files to ${config_dir_path}"


echo "You can now delete this folder."
