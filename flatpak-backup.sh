#!/bin/bash
source ./internal/error_handler.sh

# checks
if [[ $EUID -ne 0 ]]; then
  echo -e "${log_timestamp} [${red}ERROR${nc}] -- This script must be run as root!"
  exit 1
fi
if [[ -z $NFS_SHARE ]]; then
  echo -e "${log_timestamp} [${red}ERROR${nc}] -- Environment lacks required variable NFS_SHARE!"
  exit 1
fi

user_bin_path="${user_home}/bin"
bin_file="${user_bin_path}/flatback.sh"

echo -e "${log_timestamp} [INFO] -- Installing flatpak backup script..."
mkdir -p "${user_bin_path}"
cat ./internal/error_handler.sh >"${bin_file}"

cat <<-EOT >>"${bin_file}"

	# checks
	if [[ \$EUID -ne 0 ]]; then
	  echo -e "\${log_timestamp} [\${red}ERROR\${nc}] -- This script must be run as root!"
	  exit 1
	fi
	if [[ -z \$NFS_SHARE ]]; then
	  echo -e "\${log_timestamp} [\${red}ERROR\${nc}] -- Environment lacks required variable NFS_SHARE!"
	  exit 1
	fi

	restore_switch=false
	backup_dir="\${user_home}/.backup"
	flatpak_backup_dir="\${backup_dir}/flatpak"

	usage() {
	  echo "Usage: \${0} [-h|--help] [r|--restore]"
	  echo -e "\nOptions:"
	  echo -e "\n\t --help -h\tprint this message"
	  echo -e "\t --restore -r\trestore flatpaks"
	  echo -e "\nNote:"
	  echo "- running this script without any flags will initiate a backup of all installed flatpaks"
	}

	for arg in "\${@}"; do
	  case \$arg in
	  -r | --restore)
	    restore_switch=true
	    ;;
	  -h | --help)
	    usage
	    exit 1
	    ;;
	  *)
	    usage
	    echo -e "\${log_timestamp} [\${red}ERROR\${nc}] -- Unknown flag: \${arg}"
	    exit 1
	    ;;
	  esac
	done

	echo "\${log_timestamp} [INFO] -- Prevent clobbering of \${backup_dir} directory..."
	mkdir -p "\${backup_dir}"
	umount "\${backup_dir}" || echo "\${log_timestamp} [INFO] -- \${backup_dir} not mounted..."

	echo "\${log_timestamp} [INFO] -- Mounting \${NFS_SHARE} at \${backup_dir}..."
	mount -t nfs "\${NFS_SHARE}" "\${backup_dir}"

	if [[ \$restore_switch = false ]]; then

	  echo "\${log_timestamp} [INFO] -- Backing up flatpak application list..."
	  mkdir -p "\${flatpak_backup_dir}"
	  flatpak list --columns=application --app >"\${flatpak_backup_dir}/apps.list"

	  echo "\${log_timestamp} [INFO] -- Backing up flatpak application data..."
	  rsync --archive --delete --human-readable --progress --verbose --exclude="cache" "\${user_home}/.var/app" "\${flatpak_backup_dir}/"

	else
	  echo "\${log_timestamp} [INFO] -- Restoring flatpak application data..."
	  rsync --archive --human-readable --progress --verbose "\${flatpak_backup_dir}/app" "\${user_home}/.var/"

	fi

	echo "\${log_timestamp} [INFO] -- Unmounting \${backup_dir}..."
	umount "\${backup_dir}" || echo "\${log_timestamp} [INFO] -- \${backup_dir} not mounted..."
  echo -e "\${log_timestamp} [\${green}SUCCESS\${nc}] -- Completed successfully!"
EOT
chmod 770 "${bin_file}"
chown 1000:1000 "${_}"

echo "${log_timestamp} [INFO] -- Installing flatback service..."
cat <<-EOT >/usr/lib/systemd/system/flatback.service
	[Unit]
	Description=Backup flatpak data

	[Service]
	Type=oneshot
	Environment="NFS_SHARE=${NFS_SHARE}"
	ExecStart="${bin_file}"

	[Install]
	WantedBy=multi-user.target
EOT

echo "${log_timestamp} [INFO] -- Installing flatback timer..."
cat <<-EOT >/usr/lib/systemd/system/flatback.timer
	[Unit]
	Description=Run flatback every hour

	[Timer]
	OnCalendar=hourly
	Persistent=true

	[Install]
	WantedBy=timers.target
EOT

echo "${log_timestamp} [INFO] -- Enabling and starting flatback.timer..."
systemctl daemon-reload
systemctl enable --now flatback.timer

echo -e "${log_timestamp} [${green}SUCCESS${nc}] -- Completed successfully!"
