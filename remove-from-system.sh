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
if [ "$(id -g)" -ne 0 ]; then
        echo "You need to be root to remove Adsorber." 1>&2
        exit 126
fi

adsorber remove -y \
        || {
                printf "\033[0;93mSometing went wrong at running Adsorber's own removal action. Doing it the hard way...\n\033[0m"

        }

# Remove placed files from the specified locations
rm -r "${executable_dir_path}/adsorber"
rm -r "${library_dir_path}"
rm -r "${shareable_dir_path}"
rm -r "${config_dir_path}
