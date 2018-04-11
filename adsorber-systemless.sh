#!/bin/sh

parameters="$@"

echo "Running Adsorber in systemless-mode ..."

# Get the path of scripts root directory
readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

echo ""

# Call adsorber from the src/bin/ directory
("${source_dir_path}/src/bin/adsorber" "${parameters}") \
	&& {
		_exit_code=$?
		echo ""
		echo "Adsorber in systemless-mode exited with code ${_exit_code}."
	} || {
		_exit_code=$?
		
		echo ""
		# I defined exit code 80 as an error if wrong or no input has been made
		if [ "${_exit_code}" -eq 80 ]; then
			echo "You've supplied no, or wrong parameters."
		fi

		echo "Adsorber in systemless-mode exited with code ${_exit_code}. Thats an error."
	}

