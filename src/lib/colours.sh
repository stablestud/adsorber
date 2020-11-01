#!/bin/sh

# Author:     stablestud <adsorber@stablestud.org>
# Repository: https://github.com/stablestud/adsorber
# License:    MIT, https://opensource.org/licenses/MIT

# Variable naming:
# under_score        - used for global variables which are accessible between functions.
# _extra_under_score - used for local function variables. Should be unset afterwards.
#          (Note the underscore in the beginning of _extra_under_score!)

# The following variables are declared globally.
# If you run this file independently following variables need to be set:
# ---variable:---  --default value:--  ----declared in:----
# use_formatting   true                src/bin/adsorber, src/lib/cron/default-cronjob.sh, src/lib/systemd/default-service

if [ "${use_formatting}" != "false" ]; then
        readonly prefix="  "
        readonly prefix_fatal="\\033[0;91mE "   # 'E' in intensity red
        readonly prefix_info="\\033[0;97m  "    # Intensity white
        readonly prefix_input="> "
        readonly prefix_title="\\033[1;37m"     # Bold white
        readonly prefix_warning="! "
        readonly prefix_reset="\\033[0m"        # Default colour
        readonly prefix_underline="\\033[4;37m" # White Underline

        # Regular Colors
        #readonly BLACK='\033[0;30m'        # Black
        #readonly RED='\033[0;31m'          # Red
        #readonly GREEN='\033[0;32m'        # Green
        #readonly YELLOW='\033[0;33m'       # Yellow
        #readonly BLUE='\033[0;34m'         # Blue
        #readonly PURPLE='\033[0;35m'       # Purple
        #readonly CYAN='\033[0;36m'         # Cyan
        #readonly WHITE='\033[0;37m'        # White

        # Bold
        #readonly BBLACk='\033[1;30m'       # Black
        #readonly BRED='\033[1;31m'         # Red
        #readonly BGREEN='\033[1;32m'       # Green
        #readonly BYELLOW='\033[1;33m'      # Yellow
        #readonly BBLUE='\033[1;34m'        # Blue
        #readonly BPURPLE='\033[1;35m'      # Purple
        #readonly BCYAN='\033[1;36m'        # Cyan
        #readonly BWHITE='\033[1;37m'       # White

        # Underline
        #readonly UBLACK='\033[4;30m'       # Black
        #readonly URRED='\033[4;31m'        # Red
        #readonly UGREEn='\033[4;32m'       # Green
        #readonly UYELLOW='\033[4;33m'      # Yellow
        #readonly UBLUE='\033[4;34m'        # Blue
        #readonly UPURPLE='\033[4;35m'      # Purple
        #readonly UCYAN='\033[4;36m'        # Cyan
        #readonly uwhite='\033[4;37m'        # White

        # Background
        #readonly BG_BLACK='\033[40m'       # Black
        #readonly BG_RED='\033[41m'         # Red
        #readonly BG_GREEN='\033[42m'       # Green
        #readonly BG_YELLOW='\033[43m'      # Yellow
        #readonly BG_BLUE='\033[44m'        # Blue
        #readonly BG_PURPLE='\033[45m'      # Purple
        #readonly BG_CYAN='\033[46m'        # Cyan
        #readonly BG_WHITE='\033[47m'       # White

        # High Intensity
        #readonly IBLACK='\033[0;90m'       # Black
        #readonly IRED='\033[0;91m'         # Red
        #readonly IGREEN='\033[0;92m'       # Green
        #readonly IYELLOW='\033[0;93m'      # Yellow
        #readonly IBLUE='\033[0;94m'        # Blue
        #readonly IPURPLE='\033[0;95m'      # Purple
        #readonly ICYAN='\033[0;96m'        # Cyan
        #readonly IWHITE='\033[0;97m'       # White

        # Bold High Intensity
        #readonly BIBLACK='\033[1;90m'      # Black
        #readonly BIRED='\033[1;91m'        # Red
        #readonly BIGREEN='\033[1;92m'      # Green
        #readonly BIYELLOW='\033[1;93m'     # Yellow
        #readonly BIBLUE='\033[1;94m'       # Blue
        #readonly BIPURPLE='\033[1;95m'     # Purple
        #readonly BICYAB='\033[1;96m'       # Cyan
        #readonly BIWHITE='\033[1;97m'      # White

        # High Intensity backgrounds
        #readonly BG_IBLACK='\033[0;100m'   # Black
        #readonly BG_IRED='\033[0;101m'     # Red
        #readonly BG_IGREEN='\033[0;102m'   # Green
        #readonly BG_IYELLOW='\033[0;103m'  # Yellow
        #readonly BG_IBLUE='\033[0;104m'    # Blue
        #readonly BG_IPURPLE='\033[0;105m'  # Purple
        #readonly BG_ICYAN='\033[0;106m'    # Cyan
        #readonly BG_IWHITE='\033[0;107m'   # White
else
        unset prefix
        unset prefix_fatal
        unset prefix_info
        unset prefix_input
        unset prefix_title
        unset prefix_warning
        unset prefix_reset
        unset prefix_underline
fi
