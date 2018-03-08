#!/bin/sh

Cronjob_install()
{
        echo "${prefix}Installing cronjob ..."

        if [ ! -d "${crontab_dir_path}" ]; then
                printf "%bWrong crontab_dir_path set. Can't access: %s.%b\n" "${prefix_fatal}" "${crontab_dir_path}" "${prefix_reset}" 1>&2
                remove_ErrorCleanUp
                exit 126
        fi

        # Replace the @ place holder line with binary_dir_path and copy the content to cron's directory
        sed "s|#@version@#|${version}|g" "${binary_dir_path}/bin/cron/80adsorber" \
                | sed "s|^#@\/some\/path\/adsorber\.sh update@#$|${binary_dir_path}\/adsorber\.sh update|g" \
                > "${crontab_dir_path}/80adsorber"
        chmod u=rwx,g=rx,o=rx "${crontab_dir_path}/80adsorber"

        readonly installed_scheduler="cronjob"

        return 0
}


Cronjob_remove()
{
        if [ -f "${crontab_dir_path}/80adsorber" ]; then
                rm "${crontab_dir_path}/80adsorber" \
                        && echo "${prefix}Removed Adsorber's cronjob."
        else
                echo "${prefix}Cronjob not installed. Skipping ..."
        fi

        return 0
}
