# Adsorber
[![Latest version](https://img.shields.io/badge/latest-v0.5.0-brightgreen.svg)](https://github.com/stablestud/adsorber/releases)
[![License](https://img.shields.io/github/license/stablestud/adsorber.svg)](https://github.com/stablestud/adsorber/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/stablestud/adsorber.svg)](https://github.com/stablestud/adsorber/stargazers)

(Ad)sorber blocks ads by 'absorbing' and dumbing them into void.
Technically speaking, it adds ad-domains to the hosts file `/etc/hosts` with a redirection to a non-existent ip `0.0.0.0`.
You can consider it as [Adaway](https://github.com/AdAway/AdAway) for Linux.

## Features
* Block advertisements system-wide, not only in the browser.
* Prevents annoying anti-adblockers from triggering.
* Update your ad-domain list with domains from external external sources (like https://adaway.org/hosts.txt).
* Automatically update the hosts file per cronjob or systemd service.
* Revert to the previous hosts file if the current hosts file contains broken ad-domains.
* White- and blacklist.


## Requirements
* `Linux` based distro
* `root` rights (e.g. with `sudo`)
Should be available with all distros:
* POSIX-compliant shell (`/bin/sh`)
* Support for `/etc/hosts` file
* `curl` or `wget`

## Installation
Download Adsorber from `[releases](https://github.com/stablestud/adsorber/releases)` or clone it.

Two possibilites:
1. [Place files onto system (recommended)](#Place-files-onto-system-\(recommended\)) OR
2. [Run it portable](#Run-portable)

### Place files onto system (recommended)
Adsorber will be placed onto your system (at `/usr/local/`).

1. Execute the script `./place_files_onto_system.sh`
2. Execute the command `adsorber setup` and answer the prompts to configure Adsorber.
3. You're done!

Placing Adsorber has the advantage to run it independently from the user who downloaded it and
it prevents broken cronjobs/services as there is no risk that the files/directories of Adsorber will be accidentally deleted or moved.

To configure where it should be placed (to fit your custom system), edit the relevant lines in `place_files_onto_system.sh` and `remove_files_from_system.sh`. However the default path (`/usr/local/`) is the default for external scripts on Linux (see [here](http://refspecs.linuxfoundation.org/FHS_2.3/fhs-2.3.html#USRLOCALLOCALHIERARCHY)).

### Run portable

1. Execute the script `./portable_adsorber.sh`
2. You're done!

### Some other title

By default Adsorber uses the following external sources:
* [adaway.org](https://adaway.org/hosts.txt) (also used by AdAway)
* [yoyo.org](https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext) (also used by AdAway)
To add your own ad-domain sources, just add them to the `sources.list` config file. You can find it at `/usr/local/etc/adsorber/`.

## Usage

### Default help screen of `adsorber help`
```
Usage: adsorber <operation> [<options>|--help]

(Ad)sorber blocks ads by "absorbing" and dumbing them into void.
           (with the help of the hosts file)

Operation (required):
  setup   - setup necessary things needed for Adsorber
              e.g., create backup file of hosts file,
                    create scheduler which updates the host file once a week
            However this should've been done automatically.
  update  - update hosts file with newest ad servers
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

Scheduler specifc options (use with 'setup'):
  -ns, --no-scheduler      - skip scheduler creation
  -s,  --systemd           - use Systemd ...
  -c,  --cron              - use Cronjob as scheduler
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
Note: to get further information about a operation run `adsorber <operation> --help`

#### `adsorber setup {options}`:
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

#### `adsorber update {options}`:
To keep the hosts file up-to-date.

The command will:
* copy the current `/etc/hosts` to `/etc/hosts.previous`, if not disabled in `adsorber.conf`
* download ad-server lists from servers listed in `sources.list`
* filter those and apply them to the systems hosts file `/etc/hosts`

Possible options are:
* `-f, --force`
* `-h,  --help`

#### `adsorber revert {options}`:
To revert to the last applied hosts-file by Adsorber.

The command will:
* copy `/etc/hosts.previous` to `/etc/hosts`, overwriting the newest `/etc/hosts`.

This is useful if the new hosts file contains less ad-domains, because a server
was unreachable and you don't want to loose the ad-servers supplied from this server.

Possible option:
* `-h,  --help`

#### `adsorber restore {options}`:
To restore the hosts file temporary, without removing the backup.

The command will:
* copy `/etc/hosts.original` to `/etc/hosts`, overwriting the modified `/etc/hosts` by Adsorber.

Important: If Adsorber's scheduler was set-up, it'll re-apply ad-server domains to your hosts file when triggered.
For this reason this command is used to temporary disable Adsorber, e.g. when it's blocking some sites you need access for a short period of time.
To re-apply run `adsorber update`

Possible option:
* `-h,  --help`

#### `adsorber disable {options}`:
Completely disable all background tasks (schedulers) and remove changes made by Adsorber.

The command will:
* disable all schedulers (systemd, cronjob)
* restore the hosts file to it's original state
* remove all leftovers (previous hosts-file, etc)

Possible options are:
* `-y, --yes, --assume-yes`
* `-h,  --help`

### Options (optional):

#### `-s, --systemd`:
Use with `setup`.
* Setup systemd scheduler, skipping the scheduler prompt. Files are placed into `/etc/systemd/system` by default.
#### `-c, --cronjob`:
Use with `setup`.
* Setup the cron scheduler, skipping the scheduler prompt. File is placed into `/etc/cron.weekly/` by default.
#### `-ns, --no-scheduler`:
Use with `setup`
* Skips the setup of a scheduler. You'll need to update Adsorber manually with `adsorber update`.
#### `-y, --yes, --assume-yes`:
Answers all prompts with `yes` e.g.,
* `Do you really want to setup Adsorber?`
* `Do you really want to disable Adsorber?`

It'll not answer prompts which may harm your system. But `--force` will.
#### `-f, --force`:
This will force the script to continue (dangerous) the update e.g.,
* Continues if no backup has been created, overwriting the existing hosts file.
#### `-h, --help`:
If specified with an operation, it'll show extended help about it.
#### `--noformatting`:
Disables coloured and formatted output by Adsorber. Useful for logging to files and output processing by other scripts.

## Settings:
To add or remove ad-domain sources edit the `soures.list` file which is created after the setup of Adsorber.
For a general configuration of Adsorber e.g., the path of the crontab, edit `adsorber.conf`
To add domains to the `whilelist` or `blacklist` edit the relevant files at the default config location.

The configuration's default location is at `/usr/local/etc/adsorber/` if placed onto the system.
If not, the config files should be placed at the scripts root directory.

## Todo for future releases
You're free to implement things listed/not listed in [`TODO.md`](https://github.com/stablestud/adsorber/blob/master/TODO.md)  to Adsorber.
Any additions are appreciated. :)

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
