#!/bin/sh

parameters="${*}"

printf "Running Adsorber in portable-mode"
if [ ! "${parameters}" = "" ]; then
        printf " with %s parameter(s): '%s'" "${#}" "${parameters}"
fi
printf " ...\\n"

# Get the path of scripts root directory
readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

echo ""

# Call adsorber from the src/bin/ directory
runAdsorber()
{
        ( "${source_dir_path}/src/bin/adsorber" ${parameters} )
        _exit_code="${?}"
        echo ""
}
if runAdsorber; then
        echo "Adsorber in portable-mode exited with code ${_exit_code}."
else
        # I defined exit code 80 as an error code if wrong or no input has been made
        if [ "${_exit_code}" -eq 80 ]; then
                echo "You've supplied no or wrong parameters."
        fi

        echo "Adsorber in portable-mode exited with code ${_exit_code}. Thats an error."
fi
