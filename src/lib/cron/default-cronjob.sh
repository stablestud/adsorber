#!/bin/sh
#
# (Ad)sorber v#@version@# crontab file
# Updates the hosts file #@frequency@#.
#
# For more information: https://github.com/stablestud/adsorber
# Or send me an email: <adsorber@stablestud.org>
#
# adsorber setup --cron:
# By default this file is going to be copied into /etc/cron.weekly/ if not
# other specified.

printf "\\nAdsorber v#@version@# #@frequency@# Cronjob @ %s\\n" "$(date)" >> "#@/some/path/to/logfile@#"
#@/some/path/adsorber update@# 2>&1 | tee -a "#@/some/path/to/logfile@#" | logger -i -e -t Adsorber
