#!/bin/sh

# Checks script files for errors with shellcheck.
# Can be installed via apt or yum.

readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

if ! command -v shellcheck 2>/dev/null 1>&2; then
        echo "Shellcheck must be installed."
fi

shellcheck -e SC2154 -e SC1090 -e SC2163 \
        "${script_dir_path}/../adsorber.sh" \
        "${script_dir_path}/../bin/config.sh" \
        "${script_dir_path}/../bin/install.sh" \
        "${script_dir_path}/../bin/update.sh" \
        "${script_dir_path}/../bin/revert.sh" \
        "${script_dir_path}/../bin/restore.sh" \
        "${script_dir_path}/../bin/remove.sh" \
        "${script_dir_path}/../bin/colours.sh"
