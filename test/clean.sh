#!/bin/sh

readonly source_dir_path="$(cd "$(dirname "${0}")" && pwd)"

echo "Cleaning ${source_dir_path} ..."

if [ -f "${source_dir_path}/../adsorber.conf" ]; then
	rm "${source_dir_path}/../adsorber.conf"
	echo "Removed adsorber.conf"
fi

if [ -f "${source_dir_path}/../whitelist" ]; then
	rm "${source_dir_path}/../whitelist"
	echo "Removed whitelist"
fi

if [ -f "${source_dir_path}/../blacklist" ]; then
	rm "${source_dir_path}/../blacklist"
	echo "Removed blacklist"
fi

if [ -f "${source_dir_path}/../sources.list" ]; then
	rm "${source_dir_path}/../sources.list"
	echo "Removed sources.list"
fi


