#!/bin/sh

# Checks script files for errors with shellcheck.
# Can be installed via apt, yum, pacman, stack, cabal, dnf, brew, zypper, eopkg,
# snap, docker or emerge.

readonly script_dir_path="$(cd "$(dirname "${0}")" && pwd)"

if ! command -v shellcheck 2>/dev/null 1>&2; then
        echo "Shellcheck must be installed."
	exit 1
fi

echo "Running shellcheck ..."

(
	cd -P "${script_dir_path}" || { echo "Couldn't descend to ${script_dir_path}"; exit 1; }

        shellcheck -x \
                "${script_dir_path}/shellcheck.sh" \
                "${script_dir_path}/../src/bin/adsorber" \
                "${script_dir_path}/../portable_adsorber.sh" \
                "${script_dir_path}/../place_files_onto_system.sh" \
                "${script_dir_path}/../remove_from_system.sh"

        echo "Done."
)
