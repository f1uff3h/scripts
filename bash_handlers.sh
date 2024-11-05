log() {
  local nc='\e[0m'
  local red='\e[31m'
  local green='\e[0;32m'
  local log_timestamp
  log_timestamp=$(date +"[%Y-%m-%dT%H:%M:%S]")

  case "${1,,}" in
  info)
    echo "${log_timestamp} [INFO] -- ${2}..."
    ;;
  error)
    echo -e "${log_timestamp} [${red}ERROR${nc}] -- ${2}!"
    exit 1
    ;;
  success)
    echo -e "${log_timestamp} [${green}SUCCESS${nc}] -- ${2}!"
    ;;
  *)
    echo -e "${log_timestamp} [UNKNOWN] -- INVALID LOG TYPE ${1}..."
    exit 1
    ;;
  esac
}
readonly -f log

handle_error() {
  log error "An error occured on line ${1}: '${BASH_COMMAND}' exited with status code ${?}"
}
readonly -f handle_error

handle_root() {
  if [ "${EUID}" != 0 ]; then
    log error "This script must be run as root"
  fi
}
readonly -f handle_root

handle_environment() {
  for env_var in "${@}"; do
    if [ -z "${!env_var:-}" ]; then
      log error "Missing required environment variable ${env_var}"
    fi
  done
}
readonly -f handle_environment

handle_debian() {
  if ! grep -q 'ID=debian' /etc/os-release; then
    log error "Distribution not based on Debian"
  fi
  if [ -z "${BASH}" ]; then
    log error "This script requires bash"
  fi

  log info "Upgrading system"
  apt-get update && apt-get upgrade -y
}
readonly -f handle_debian

trap 'handle_error $LINENO' ERR

exec &>> >(tee -a "/var/log/$(basename "${0}")")
