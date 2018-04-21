#!/bin/sh

# Checks script files for errors with shellcheck.
# Can be installed via apt or yum.

readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

if ! command -v shellcheck 2>/dev/null 1>&2; then
        echo "Shellcheck is not installed."
fi

echo "Running shellcheck ..."

shellcheck -x \
        "${source_dir_path}/../src/bin/adsorber" \
        "${source_dir_path}/../portable_adsorber.sh" \
        "${source_dir_path}/../install_to_system.sh" \
        "${source_dir_path}/../remove_from_system.sh" \
        "${source_dir_path}/shellcheck.sh"
