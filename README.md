# Adsorber
[![Latest version](https://img.shields.io/badge/latest-v0.5.2-brightgreen.svg)](https://github.com/stablestud/adsorber/releases)
[![License](https://img.shields.io/github/license/stablestud/adsorber.svg)](https://github.com/stablestud/adsorber/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/stablestud/adsorber.svg)](https://github.com/stablestud/adsorber/stargazers)

(Ad)sorber blocks ads by 'absorbing' and dumbing them into void.    
Technically speaking, it adds ad-domains to the hosts file `/etc/hosts` with a redirection to a non-existent ip `0.0.0.0`.    
You can consider it as [AdAway](https://github.com/AdAway/AdAway) for Linux machines.

## Index
* [Features](#features)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Logging](#logging)
* [License](#license)

## Features
* Blocks advertisements system-wide, not only in the browser.
* Prevents annoying anti-adblockers from triggering.
* Update your ad-domain list with domains from external external sources (like https://adaway.org/hosts.txt).
* Automatically update the hosts file with schedulers (cronjob or systemd service).
* Revert to the previous hosts file if the current hosts file contains broken ad-domains.
* White- and blacklist.

## Requirements
* `root` rights (e.g. with `sudo`)
* The following should be supported on all distros by default:
  * `/bin/sh`
  * `/etc/hosts`
  * `curl` or `wget`

## Installation
Download Adsorber from [`releases`](https://github.com/stablestud/adsorber/releases) or clone it.

__Two possibilites:__
* [Install](#install-recommended) to system (recommended)
* [Portable mode](#portable-mode) without installation

### Install (recommended)
Adsorber will be placed onto your system (to `/usr/local/`).

1. Execute the file `./place_files_onto_system.sh`
2. Run the command `adsorber setup`
3. Answer the prompts to configure Adsorber
4. Finished! You can remove the downloaded files.

If you have a super custom system you can configure where Adsorber should be placed, edit the relevant lines in `place_files_onto_system.sh` and `remove_files_from_system.sh`     
However the default path (`/usr/local/`) is the default for external scripts on Linux (see [here](http://refspecs.linuxfoundation.org/FHS_2.3/fhs-2.3.html#USRLOCALLOCALHIERARCHY)) and should be fine for most systems.

Placing Adsorber has the advantage to run it independently from the user who downloaded it,
preventing broken cronjobs/services as there is no risk that the files/directories of Adsorber will be accidentally deleted or moved.

To reverse the steps (complete uninstall) run the script `./remove_files_from_system`.

### Portable mode
This mode will only download the recent ad-domains and merges them into your hosts file.     
You won't be able to set a scheduler.

1. Execute `./portable_adsorber.sh setup` to generate the config files
2. Execute `./portable_adsorber.sh setup` again to continue
3. Finished!

If you want to update your hosts file you need to do it yourself by running `./portable_adsorber.sh update`

Portable-mode won't touch the system except for `/etc/hosts` which is required to block ad-servers. A backup of it will be created at `/etc/hosts.original`.

## Usage

### `adsorber <operation> [<options>]`
* [Operation](#operations-required)
* [Options](#options-optional)

### Default help screen of `adsorber help`
```
Usage: adsorber <operation> [<options>|--help]

(Ad)sorber blocks ads by "absorbing" and dumbing them into void.
           (with the help of the hosts file)

Operation (required):
  setup   - setup necessary things needed for Adsorber
              e.g., create backup file of hosts file,
                    create scheduler which updates the host file once a week
  update  - update hosts file with the newest ad-domains
  restore - restore hosts file to its original state
           (it does not remove the scheduler, this should be used temporary)
  revert  - reverts the hosts file to the last applied (previous) host file.
  disable - completely remove changes made by Adsorber
              e.g., disable scheduler (if set)
                    restore hosts file to its original state
  version - show version of this shell script
  help    - show this help

Options (optional):
  -y,  --yes, --assume-yes - answer all prompts with 'yes'
  -f,  --force             - force the update if no /etc/hosts backup
                             has been created (dangerous)
  -h,  --help              - show specific help of specified operations
                             (e.g 'adsorber update --help)
  --noformatting           - turn off coloured and formatted output

Scheduler options (use with 'setup'):
  -ns, --no-scheduler      - skip scheduler creation
  -s,  --systemd           - setup Systemd as scheduler
  -c,  --cron              - setup Cronjob ...
  -H,  --hourly            - run scheduler once hourly
  -D,  --daily                              ... daily
  -W,  --weekly                             ... weekly
  -M,  --monthly                            ... monthly
  -Q,  --quarterly                          ... quarterly (4x a year)
  -S,  --semiannually                       ... semiannually (2x a year)
  -Y,  --yearly                             ... yearly

Config files are located at: /usr/local/etc/adsorber/

Documentation: https://github.com/stablestud/adsorber
If you encounter any issues please report them to the Github repository.
```

### Operations (required):
To run Adsorber one of the following operations must be given as first parameter.

Note: to get further information about a operation run `adsorber <operation> --help`

* [setup](#adsorber-setup-options)
* [update](#adsorber-update-options)
* [revert](#adsorber-revert-options)
* [restore](#adsorber-restore-options)
* [disable](#adsorber-disable-options)

### adsorber `setup {options}`:
You should run this command first.    

The command will:
* backup your `/etc/hosts` file to `/etc/hosts.original` (if not other specified in `adsorber.conf`)
* setup a scheduler which updates your hosts file with ad-server domains once a week. (either systemd, cronjob or none)
* fetch the newest ad-server domains in your hosts file. (same as `update`)

Possible options are:
* `-s,  --systemd`
* `-c,  --cronjob`
* `-ns, --no-scheduler`
* `-y,  --yes, --assume-yes`
* `-h,  --help`
* `-H,  --hourly`
* `-D,  --daily`
* `-W,  --weekly`
* `-M,  --monthly`
* `-Q,  --quarterly`
* `-S,  --semiannually`
* `-Y,  --yearly`

### adsorber `update {options}`:
Updates the hosts file with the latest ad-domains.

The command will:
* copy the current `/etc/hosts` to `/etc/hosts.previous`, if not disabled in `adsorber.conf`
* download ad-server domains from servers listed in `sources.list`
* filter those and apply them to the systems hosts file `/etc/hosts`

Possible options are:
* `-f, --force`
* `-h,  --help`

### adsorber `revert {options}`:
Reverts the last applied hosts-file by Adsorber.
 
The command will:
* copy `/etc/hosts.previous` to `/etc/hosts`, overwriting the newest `/etc/hosts`.

This is useful if the newest hosts file contains less or no ad-domains, because a source
was unreachable and you don't want to loose the ad-servers supplied previously from this source.

Possible option:
* `-h,  --help`

### adsorber `restore {options}`:
Restores the hosts file to its original state, without removing its backup and scheduler.

The command will:
* copy `/etc/hosts.original` to `/etc/hosts`, overwriting the modified `/etc/hosts` by Adsorber.

Important: If Adsorber's scheduler was set-up, it'll re-apply ad-server domains to your hosts file when triggered.     
For this reason this command is used to temporary disable Adsorber, e.g. when it's blocking some sites you need to access for a short period of time.     
To re-apply run `adsorber revert` (for previous host file) or `adsorber update` (for updated version).

Possible option:
* `-h,  --help`

### adsorber `disable {options}`:
Completely disable all background tasks (schedulers) and remove all changes made by Adsorber.

The command will:
* disable all schedulers (systemd, cronjob)
* restore the hosts file to it's original state
* remove all leftovers (previous hosts file, etc)

Possible options are:
* `-y, --yes, --assume-yes`
* `-h,  --help`

### Options (optional):
* [-s, --systemd](#-s--systemd)
* [-c, --cronjon](#-c--cronjob)
* [-ns, --no-scheduler](#-ns--no-scheduler)
* [-y, --yes, --assume-yes](#-y--yes--assume-yes)
* [-f, --force](#-f--force)
* [-h, --help](#-h--help)
* [--noformatting](#--noformatting)

#### `-s, --systemd`:

Option is only available with operation `setup`.     
Adsorber uses Systemd as a scheduler to update your hosts file periodically.

* Setup systemd scheduler, skipping the scheduler prompt.      

Files are placed into `/etc/systemd/system` by default.

#### `-c, --cronjob`:

Option is only available with operation `setup`.     
Adsorber uses Cronjob as a default scheduler to update your hosts file periodically.

* Setup the cron scheduler, skipping the scheduler prompt. 

File is placed into `/etc/cron.weekly/` by default.

#### `-ns, --no-scheduler`:
Option is only available with operation `setup`.     
Tells Adsorber to not install a scheduler.

* Skips the setup of a scheduler, therefore skipping the scheduler prompt. 

Adsorber won't update the host file periodically, therefore    
you'll have to update it manually with `adsorber update`.

#### `-y, --yes, --assume-yes`:

Answers all prompts with `yes` e.g.,
* `Do you really want to setup Adsorber?`
* `Do you really want to disable Adsorber?`

Note: it'll not answer prompts which may harm your system. But `--force` will.

#### `-f, --force`:

Option is only available with operation `update`.

This will force the script to continue (dangerous!) the update e.g.,
* Continues if no backup has been created, overwriting the existing hosts file.

#### `-h, --help`:

Show general help or ff specified with an operation,    
it'll show specific help about it e.g.,    
`adsorber setup --help`

#### `--noformatting`:
Disables coloured and formatted output by Adsorber.     
Useful for logging to files and output processing by other scripts.

## Configuration:

By default the config files are located at `/usr/local/etc/adsorber/`.     
In portable-mode the config files are being created at the scripts root directory after the first run.

Config files you may want to edit:
* `adsorber.conf` - general configuration
* `sources.list`  - sources to fetch from
* `whitelist`     - domains which should not be blocked
* `blacklist`     - domains which should be always blocked

By default Adsorber uses the following external sources:
* [adaway.org](https://adaway.org/hosts.txt) (also used by AdAway)
* [yoyo.org](https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext) (also used by AdAway)

To add your own ad-domain sources, just add them to `sources.list`.

## Logging:

Schedulers (systemd service or cronjob) will pass their output to the Syslog process and to `/var/log/adsorber.log`.      
The syslog can be examined at `/var/log/syslog`.

## Todo for future releases
You're free to implement things listed -or- not listed in [`TODO.md`](https://github.com/stablestud/adsorber/blob/master/TODO.md)  to Adsorber.
Any additions are always appreciated. :)

## License
[![License](https://img.shields.io/github/license/stablestud/adsorber.svg)](https://github.com/stablestud/adsorber/blob/master/LICENSE)
```
MIT License

Copyright (c) 2017 stablestud

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the Software), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
