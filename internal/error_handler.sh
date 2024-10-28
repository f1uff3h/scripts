#!/bin/bash

set -e

readonly red='\e[31m'
readonly nc='\e[0m'
readonly green='\e[0;32m'
readonly log_timestamp=$(date +"[%Y-%m-%dT%H:%M:%S]")

# NOTE: for single user envs, needs changing for multi-user envs
user_home=$(grep 1000 /etc/passwd | cut -d ":" -f6)

handle_error() {
  echo -e "${log_timestamp} [${red}ERROR${nc}] -- An error occured on line ${1}: '${BASH_COMMAND}' exited with status code ${?}"
  exit 1
}

trap 'handle_error $LINENO' ERR

exec &>> >(tee -a "/var/log/$(basename $0)")
