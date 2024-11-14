#!/bin/bash

source <(curl -s https://codeberg.org/f1uff3h/scripts/raw/branch/main/bash_handlers.sh)

user_home=$(grep 1000 /etc/passwd | cut -d ":" -f6)
readonly env_vars=('NFS_SHARE')
readonly flatback_binary="${user_home}/bin/flatback.sh"

handle_root
handle_environment "${env_vars[@]}"

log info "Installing flatpak backup script"
mkdir -p "${flatback_binary%/*}"
echo "#!/bin/bash" >"${flatback_binary}"
curl https://codeberg.org/f1uff3h/scripts/raw/branch/main/bash_handlers.sh >>"${flatback_binary}"

cat <<-EOT >>"${flatback_binary}"

	readonly env_vars=('NFS_SHARE')
	user_home="${user_home}"
  readonly user_home
	handle_root
	handle_environment "\${env_vars[@]}"

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
	    log error "Unknown flag: \${arg}"
	    exit 1
	    ;;
	  esac
	done

	log info "Prevent clobbering of \${backup_dir} directory"
	mkdir -p "\${backup_dir}"
	umount "\${backup_dir}" || log info "\${backup_dir} not mounted"

	log info "Mounting \${NFS_SHARE} at \${backup_dir}"
	mount -t nfs "\${NFS_SHARE}" "\${backup_dir}"

	if [[ \$restore_switch = false ]]; then

	  log info "Backing up flatpak application list"
	  mkdir -p "\${flatpak_backup_dir}"
	  flatpak list --columns=application --app >"\${flatpak_backup_dir}/apps.list"

	  log info "Backing up flatpak application data"
	  rsync --archive --delete --human-readable --partial --progress --verbose --exclude="cache" "\${user_home}/.var/app" "\${flatpak_backup_dir}/"

	else
	  log info "Restoring flatpak application data"
	  rsync --archive --human-readable --progress --verbose "\${flatpak_backup_dir}/app" "\${user_home}/.var/"
	fi

	log info "Unmounting \${backup_dir}"
	umount "\${backup_dir}" || log info "\${backup_dir} not mounted"
	log success "Completed successfully"
EOT
chmod 770 "${flatback_binary}"
chown 1000:1000 "${_}"

log info "Installing flatback service"
cat <<-EOT >/usr/lib/systemd/system/flatback.service
	[Unit]
	Description=Backup flatpak data

	[Service]
	Type=oneshot
	Environment="NFS_SHARE=${NFS_SHARE}"
	ExecStart="${flatback_binary}"

	[Install]
	WantedBy=multi-user.target
EOT

log info "Installing flatback timer"
cat <<-EOT >/usr/lib/systemd/system/flatback.timer
	[Unit]
	Description=Run flatback every hour

	[Timer]
	OnCalendar=hourly
	Persistent=true

	[Install]
	WantedBy=timers.target
EOT

log info "Enabling and starting flatback.timer"
systemctl daemon-reload
systemctl enable --now flatback.timer

log success "Completed successfully"
