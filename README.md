# Adsorber
A(d)sorber blocks ads by 'absorbing' and dumbing them into void.
Technically speaking, it adds ad domains to the hosts file `/etc/hosts` with a redirection to a non-existent ip `0.0.0.0`.

## Features
* Block advertisements system-wide, not only in the browser.
* Prevents annoying anti-adblockers from triggering.
* Installation and remove built-in.
* Update hosts from external hosts-servers (like https://adaway.org/hosts.txt).
* Automatically update the hosts file with cron or systemd.timer.
* White- and blacklist.
* Temporary disable the adblocking.
* Filter dangerous hosts redirections.

Also it saves data, speeds up loading time and prevents some tracking of your browsing habits. For extensive privacy, I recommend using the script along browser add-ons like  [NoScript](https://addons.mozilla.org/en-US/firefox/addon/noscript/) (for [Firefox 56 and below](https://noscript.net/getit)), [Privacy Badger](https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/) and [HTTPS Everywhere](https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/).

Currently we are using the following hosts lists:
* [adaway.org](https://adaway.org/hosts.txt)
* [yoyo.org](https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext)
* & more to come.

To add your own hosts lists, just add them to the `sources.list` file.

## Usage

```
Usage: ./adsorber.sh [OPERATION] {options}

A(d)sorber blocks ads by 'absorbing' and dumbing them into void.
           (with the help of the hosts file)

Operations:
  install - setup necessary things needed for adsorber
              e.g., create backup file of hosts file,
                    create scheduler which updates the host file once a week.
  update  - update hosts file with newest ad servers
  revert  - revert hosts file to its original state
            (it does not remove the schedule, so this should be used temporary)
  remove  - completely remove changes made by adsorber
              e.g., remove scheduler (if set)
                    revert hosts file (if not already done)
  version - show version of this shell script
  help    - show this help

Options: (not required)
  -s,  --systemd           - use systemd ...
  -c,  --cron              - use cron as scheduler (use with 'install')
  -ns, --no-scheduler      - set no scheduler (use with 'install')
  -y,  --yes, --assume-yes - answer all prompts with 'yes'
  -f,  --force             - force the update if no /etc/hosts backup
                             has been created (dangerous)"

Documentation: https://github.com/stablestud/adsorber
If you encounter any issues please report them to the Github repository.
```
### Operations: (required)
#### `adsorber.sh install {options}`:
You should run this command first.
The command will:
* backup your `/etc/hosts` file to `/etc/hosts.original` (if not other specified in `adsorber.conf`)
* install a scheduler which updates your hosts file with ad-server domains once a week. (either systemd, cronjob or none)
* install the newest ad-server domains in your hosts file.

Possible options are:
* `-s,  --systemd`
* `-c,  --cronjob`
* `-ns, --no-scheduler`
* `-y,  --yes, --assume-yes`
#### `adsorber.sh update {options}`:
To keep the hosts file up-to-date.
The command will:
* install the newest ad-server domains in your hosts file.

Possible option:
* `-f, --force`
#### `adsorber.sh revert`:
To restore the hosts file temporary, without removing the backup.
The command will:
* copy `/etc/hosts.original` to `/etc/hosts`, overwriting the modified `/etc/hosts` by adsorber.

Important: If you have a scheduler installed, it'll re-apply ad-server domains to your hosts file when triggered.    
For this reason this command is used to temporary disable Adsorber, e.g. when it's blocking some sites you need access for a short period of time.    
To re-apply run `asdorber.sh update`
#### `adsorber remove {options}`:
To completely remove changes made by Adsorber.
The command will:
* remove all schedulers (systemd, cronjob)
* restore the hosts file to it's original state
* remove all leftovers

Possible options are:
* `-y, --yes, --assume-yes`

### Options:

#### `-s, --systemd`
Used with `install`.    
It installs the systemd.timer scheduler, skipping the scheduler prompt.
Files are placed into `/etc/systemd/system` by default.
#### `-c, --cronjob`
Used with `install`.    
It installs the cron scheduler, skipping the scheduler prompt.
File is placed into `/etc/cron.weekly/` by default.    
#### `-ns, --no-scheduler`
Used with `install`
It will skip the installation of a scheduler. You'll need to update adsorber manually.    
#### `-y, --yes, --assume-yes`
Answers all prompts with `yes` e.g.,
* `Do you really want to install Adsorber?`
* `Do you really want to remove Adsorber?`

It'll not answer prompts which may harm your system. But `--force` will do it.
#### `-f, --force`
This will force the script to continue (dangerous) the update e.g.,
* Continue if no backup has been created, overwriting the existing hosts file.

## Settings:
To add or remove sources edit the `soures.list` file which is created after the installation of Adsorber.    
You can edit e.g., the path of the crontab installation etc, in `adsorber.sh`    
To change the content of <strong>placed</strong> files go to:
* `bin/systemd` to edit the systemd files which are installed then as a service. <br/>You may want to run `adsorber.sh install --systemd` afterwards.
* `bin/cron` to edit the crontab. Run `adsorber.sh install --cron` afterwards to apply the changes.
* `bin/components` to edit the header and the 'title' of the hosts file modified by Adsorber.

## Todo for future releases

* Add testing framework (travis etc.)
* Make script shell independent
* Create .deb
* Integrate into package managers
## License
[MIT License](https://github.com/stablestud/adsorber/blob/master/LICENSE)    
This is free software: you are free to change and redistribute it.    
There is NO WARRANTY, to the extent permitted by law.
