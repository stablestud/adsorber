#!/bin/sh

# Checks script files for errors with shellcheck.
# Can be installed via apt or yum.

readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

if ! command -v shellcheck 2>/dev/null 1>&2; then
        echo "Shellcheck must be installed."
fi

echo "Running shellcheck ..."

shellcheck -e SC2154 -e SC1090 -e SC2163 \
        "${script_dir_path}/../src/adsorber.sh" \
        "${script_dir_path}/../src/config.sh" \
        "${script_dir_path}/../src/install.sh" \
        "${script_dir_path}/../src/update.sh" \
        "${script_dir_path}/../src/revert.sh" \
        "${script_dir_path}/../src/restore.sh" \
        "${script_dir_path}/../src/remove.sh" \
        "${script_dir_path}/../src/colours.sh"
