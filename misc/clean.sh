#!/bin/sh

readonly source_dir_path="$(cd "$(dirname "${0}")"/.. && pwd)"

echo "Cleaning ${source_dir_path} ..."

if [ -f "${source_dir_path}/adsorber.conf" ]; then
	rm "${source_dir_path}/adsorber.conf" -f
	echo "Removed adsorber.conf"
fi

if [ -f "${source_dir_path}/whitelist" ]; then
	rm "${source_dir_path}/whitelist" -f
	echo "Removed whitelist"
fi

if [ -f "${source_dir_path}/blacklist" ]; then
	rm "${source_dir_path}/blacklist" -f
	echo "Removed blacklist"
fi

if [ -f "${source_dir_path}/sources.list" ]; then
	rm "${source_dir_path}/sources.list" -f
	echo "Removed sources.list"
fi

echo "Done."
