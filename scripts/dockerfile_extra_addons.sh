#!/bin/bash

home_directory="/home/odoo"
base_directory="/opt/odoo_dir"
odoo_custom_repos="$base_directory/repos"
odoo_oca_repos="$base_directory/repos_oca"
odoo_non_ent_repos="$base_directory/repos_non_ent"


function check_status_file() {
  FILE_PATH="$1"
  if [[ -d "$FILE_PATH" ]]; then
    echo "$FILE_PATH exists on your filesystem."
  else
    touch "$FILE_PATH"
  fi
}
function getRequirements() {
    directory="$1"
    find ${directory} -type f -name 'requirements.txt' -exec cat {} \; -exec echo \; >> $destiny_req_path
    find ${directory} -type f -name '.env' -exec cat {} \; -exec echo \; >> $destiny_env_path
}

function installExtraPackages(){
    path_env="$home_directory/env-data.txt"
    while IFS= read -r env_line || [[ -n "$env_line" ]]; do
        if [ ! -z "$env_line" ]; then
            command_line="$env_line -y"
            $command_line
        fi
    done <$path_env

    error=$?; if [ $error -eq 0 ]; then echo " Installed correctly linux packages for extra addons"; else echo "ERROR: $error"; fi
}

destiny_env_path="$home_directory/env-data.txt"
destiny_req_path="$home_directory/custom-requirements.txt"

check_status_file $destiny_env_path
check_status_file $destiny_req_path

getRequirements ${odoo_custom_repos}
getRequirements ${odoo_oca_repos}
getRequirements ${odoo_non_ent_repos}

installExtraPackages
