# Adsorber
A(d)sorber blocks ads by 'absorbing' and dumbing them into void.
Technically speaking, it adds ad domains to the hosts file with a redirection to a non-existent ip `0.0.0.0`.

Also it saves data, speeds up loading time and prevents some tracking of your browsing habits. For extensive privacy, I recommend using the script along browser add-ons like  [NoScript](https://addons.mozilla.org/en-US/firefox/addon/noscript/) (for [Firefox 56 and less](https://noscript.net/getit)), [Privacy Badger](https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/) and [HTTPS Everywhere](https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/).

## Usage

`./adsorber.sh --help`:
```
Usage: ./adsorber.sh [OPERATION] {options}

A(d)sorber blocks ads by 'absorbing' and dumbing them into void.
           (with the help of the hosts file)

Operations:
  setup   - setup necessary things needed for adsorber
              e.g., create backup file of hosts file,
                    create a list with host sources to fetch from
  update  - update hosts file with newest ad servers
  revert  - revert hosts file to its original state
            (it does not remove the schedule, this should be used temporary)
  remove  - completely remove changes made by adsorber
              e.g., remove scheduler (if set)
                    revert hosts file (if not already done)
  version - show version of this shell script
  help    - show this help

Options: (not required)
  -s, --systemd  set systemd ...
  -c, --cronjob  set cronjob as scheduler (use with 'setup')
  echo "  -y, --yes      answer all prompts with 'yes'
```

## Todo

* Add simulate option
* Add comments
* Add config file
* Add proper exit codes as in [Reserved Exit Codes](http://tldp.org/LDP/abs/html/exitcodes.html#EXITCODESREF)
* Add testing framework (travis etc.)
* Port script to shell independent
* Create .deb
* Integrate into package managers
