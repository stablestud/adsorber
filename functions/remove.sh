#!/bin/bash

removeSystemd() {
  return 0
}

removeCronjob(){
  return 0
}

remove() {
  removeSystemd
  removeCronjob
  return 0
}
