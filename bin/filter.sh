#!/bin/bash

filterDomains() {
  cat "${TMP_DIR_PATH}/hosts.fetched" \
    | sed 's/\r/\n/g' \
    | sed 's/^\s*127\.0\.[01]\.1/0\.0\.0\.0/g' \
    | sed -n '/^\s*0\.0\.0\.0\s\+.\+/p' \
    | sed 's/\s\+#.*//g' \
    | sed 's/[[:blank:]]\+/ /g' \
    | sed -n '/^0\.0\.0\.0\s.*\..*/p' \
    | sed -n '/\.local\s*$/!p' \
    >> "${TMP_DIR_PATH}/hosts.filtered"
  # - replace OSX '\r' and MS-DOS '\r\n' with Unix '\n' (linebreak)
  # - replace 127.0.0.1 and 127.0.1.1 with 0.0.0.0
  # - only keep lines starting with 0.0.0.0
  # - remove inline '#' comments
  # - replace tabs and multiple spaces with one space
  # - remove domains without a dot (e.g localhost , loopback , ip6-allnodes , etc...)
  # - remove domains that are redirecting to *.local
  return 0
}

sortDomains() {
  # Sort the domains by alphabet and also remove duplicates
  sort "${TMP_DIR_PATH}/hosts.filtered" -f -u -o "${TMP_DIR_PATH}/hosts.sorted"
  return 0
}
