#!/bin/bash

revertHostsFile() {
  mv "${HOSTS_PATH}.bck" "${HOSTS_PATH}"
  return 0
}
