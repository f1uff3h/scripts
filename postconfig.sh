#!/bin/bash

RED='\e[0;31m'
NC='\e[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "\n${RED}[ERROR]Please run as root!${NC}"
  exit 1
fi

# TODO: move below to archsin
echo -e "\n[INFO] -- Configuring firewalld..."
firewall-cmd --zone=public --add-service=kdeconnect --permanent

# TODO: configure celeste and drop these
echo -e "\n[INFO] -- Adding NFS to fstab..."
cat <<-EOT >>/etc/fstab
	# /home/peco/Documents
	nfs.camarad.tech:/mnt/storage/peco/Documents    /home/peco/Documents    nfs     rw,noauto,user,relatime,soft,timeo=100,retrans=2                0       0
	# /home/peco/Downloads
	nfs.camarad.tech:/mnt/storage/peco/Downloads    /home/peco/Downloads    nfs     rw,noauto,user,relatime,soft,timeo=100,retrans=2                0       0
	# /home/peco/Pictures
	nfs.camarad.tech:/mnt/storage/peco/Pictures     /home/peco/Pictures     nfs     rw,noauto,user,relatime,soft,timeo=100,retrans=2                0       0
	# /home/peco/Videos
	nfs.camarad.tech:/mnt/storage/peco/Videos       /home/peco/Videos       nfs     rw,noauto,user,relatime,soft,timeo=100,retrans=2                0       0
	# /home/peco/repos
	nfs.camarad.tech:/mnt/storage/peco/repos        /home/peco/repos        nfs     rw,noauto,user,dev,exec,relatime,soft,timeo=100,retrans=2                0       0
EOT

echo -e "\n[INFO] -- Adding NFS mount script..."
cat <<-EOT >/home/peco/bin/nfsmount.sh
	#!/bin/bash
	mount /home/peco/Documents/
	mount /home/peco/Downloads/
	mount /home/peco/Pictures/
	mount /home/peco/Videos/
	mount /home/peco/repos/
EOT
chmod +x /home/peco/bin/nfsmount.sh
chown peco:peco /home/peco/bin/nfsmount.sh

echo -e "\n[INFO] -- Adding NFS mount script to autostart..."
mkdir -p /home/peco/.config/autostart
cat <<-EOT >/home/peco/.config/autostart/NFSMount.desktop
	[Desktop Entry]
	Type=Application
	Exec=/home/peco/bin/nfsmount.sh
	Terminal=false

	Name=NFSMount
	GenericName=Script
	StartupNotify=true
EOT
chown peco:peco /home/peco/.config/autostart/NFSMount.desktop

# TODO: configure flatpak backup and drop this
echo -e "\n[INFO] -- Adding backup script..."
cat <<-EOT >/home/peco/bin/backup.sh
	#!/bin/bash

	set -e

	RED='\e[0;31m'
	NC='\e[0m'

	restore=false

	usage() {
	  echo -e "\nUsage: backup.sh\n"
	  echo -e "\nOptions:"
	  echo -e "\t-h\tDisplay help"
	  echo -e "\t-r\tRestore backup\n"
	  exit 0
	}

	while getopts "hr" opt; do
	  case \$opt in
	  h)
	    usage
	    ;;
	  r)
	    restore=true
	    ;;
	  \?)
	    echo -e "\n\${RED}[ERROR] -- Invalid option!\${NC}"
	    exit 1
	    ;;
	  esac
	done

	echo -e "\n[INFO] -- Mounting NFS share..."
	mkdir -p /home/peco/mnt
	sudo mount -t nfs nfs.camarad.tech:/mnt/storage/peco/misc /home/peco/mnt/

	if \$restore; then
	  echo -e "\n[INFO] -- Restoring backup..."
	  rsync -avrh --progress /home/peco/mnt/ /home/peco/
	  echo -e "\n[INFO] -- Restore completed..."
	else
	  echo -e "\n[INFO] -- Backup started..."
	  rsync -avrh --progress --delete /home/peco/.waterfox /home/peco/mnt/
	  rsync -avrh --progress --delete /home/peco/.mozilla /home/peco/mnt/
	  rsync -avrh --progress --delete /home/peco/.config/BraveSoftware/ /home/peco/mnt/
	  rsync -avrh --progress --delete /home/peco/.ssh /home/peco/mnt/
	  rsync -avrh --progress --delete /home/peco/.gitconfig /home/peco/mnt/
	  echo -e "\n[INFO] -- Backup completed..."
	fi

	sudo umount /home/peco/mnt/
EOT
chmod +x /home/peco/bin/backup.sh
chown peco:peco /home/peco/bin/backup.sh

sudo -u peco /bin/bash -e -- <<-EOT
	/home/peco/bin/backup.sh -r
	pushd /home/peco/
	git clone --bare git@github.com:f1uff3h/.files/
	git --git-dir=/home/peco/.files.git/ --work-tree=/home/peco checkout 2>&1 | awk '/\s+\./{print $1}' | xargs -I{} rm -rf {}
	git --git-dir=/home/peco/.files.git/ --work-tree=/home/peco checkout 
EOT

systemctl daemon-reload

if dmidecode -s system-family | grep -q "ThinkPad T15 Gen 1" || dmidecode -s system-product-name | grep -q "20S6003NRI"; then
  echo -e "\n[INFO] -- Thinkpad T15 detected"

  echo -e "\n[INFO] -- Installing sof-firmware..."
  pacman -S sof-firmware

  echo -e "\n[INFO] -- Disabling NVIDIA GPU..."
  cat <<-EOT >/etc/modprobe.d/disable-nouveau.conf
		blacklist nouveau
		options nouveau modeset=0
	EOT

  cat <<-EOT >/etc/udev/rules.d/00-remove-nvidia.rules
		# Remove NVIDIA USB xHCI Host Controller devices, if present
		ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"

		# Remove NVIDIA USB Type-C UCSI devices, if present
		ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"

		# Remove NVIDIA Audio devices, if present
		ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"

		# Remove NVIDIA VGA/3D controller devices
		ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
	EOT
fi

# TODO: add surface pro 3 setup here
