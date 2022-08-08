#!/bin/bash

all_repos="repos.csv"
non_ent_repos="repos_non_ent.csv"
branch_odoo_version=$1
username=$2
token=$3


function check_status_directory() {
  DIRECTORY="$1"
  if [[ -d "$DIRECTORY" ]]; then
    echo "$DIRECTORY exists on your filesystem."
  else
    mkdir "$DIRECTORY"
  fi
}


function check_status_non_ent_repositories() {
  NON_ENT_DIRECTORY="$1"
  BASE_OWN_DIRECTORY="$2"
  NON_ENT_CSV="$3"
  ENTERPRISE_DIR="$BASE_OWN_DIRECTORY/enterprise"

  if [[ -d $ENTERPRISE_DIR ]]; then
      while IFS=, read -r MOD_NAME_LINE
      do
          MODULE="$ENTERPRISE_DIR/$MOD_NAME_LINE"
          cp -r "$MODULE" "$NON_ENT_DIRECTORY"
          echo "Module $MOD_NAME_LINE was moved."
          if [ "$MOD_NAME_LINE" == "hr_payroll_account" ]; then
              old_text=", 'account_accountant'"
              new_text="    'depends': ['hr_payroll'],"
              sed -i "/$old_text/c\\$new_text" "$NON_ENT_DIRECTORY/$MOD_NAME_LINE/__manifest__.py"
              echo "enterprise dependency over $MOD_NAME_LINE was removed"
          fi
      done < "$NON_ENT_CSV"
  fi
}

function clone_repositories() {
  MAIN_DIRECTORY="$1"
  REPOS_CSV="$2"
  VERSION="$3"
  DEV="$4"
  python3 check_repos_extra.py "${MAIN_DIRECTORY}" "${REPOS_CSV}" "$VERSION" "$DEV" "$username" "$token"
}

odoo_base_directory="odoo_dir"

odoo_base_own_directory="$odoo_base_directory/repos"
odoo_base_oca_directory="$odoo_base_directory/repos_oca"
odoo_non_ent_directory="$odoo_base_directory/repos_non_ent"

check_status_directory "$odoo_base_directory"
check_status_directory "$odoo_base_own_directory"
check_status_directory "$odoo_base_oca_directory"
check_status_directory "$odoo_non_ent_directory"



if [[ $branch_odoo_version == *"dev"* ]]; 
then
	clone_repositories "$odoo_base_directory" "$all_repos" "$branch_odoo_version" "true"
    if [[ -f $non_ent_repos ]];
    then
        check_status_non_ent_repositories "$odoo_non_ent_directory" "$odoo_base_oca_directory" "$non_ent_repos"
    else
        echo "Not evaluating non_ent repos"
    fi

else

	clone_repositories "$odoo_base_directory" "$all_repos" "$branch_odoo_version" "false"

    if [[ -f $non_ent_repos ]];
    then
        check_status_non_ent_repositories "$odoo_non_ent_directory" "$odoo_base_oca_directory" "$non_ent_repos"
    else
        echo "Not evaluating non_ent repos"
    fi

fi
