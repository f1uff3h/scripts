#!/bin/bash

source >(curl -s https://codeberg.org/f1uff3h/scripts/raw/branch/main/bash_handlers.sh)

handle_root

# TODO: move below to archsin
log info "Configuring firewalld"
firewall-cmd --zone=public --add-service=kdeconnect --permanent

# TODO: configure celeste and drop these
log info "Adding NFS to fstab..."
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

log info "Adding NFS mount script..."
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

log info "Adding NFS mount script to autostart..."
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

sudo -u peco /bin/bash -e -- <<-EOT
	pushd /home/peco/
	git clone --bare git@github.com:f1uff3h/.files/
	git --git-dir=/home/peco/.files.git/ --work-tree=/home/peco checkout 2>&1 | awk '/\s+\./{print $1}' | xargs -I{} rm -rf {}
	git --git-dir=/home/peco/.files.git/ --work-tree=/home/peco checkout 
EOT
systemctl daemon-reload

if dmidecode -s system-family | grep -q "ThinkPad T15 Gen 1" || dmidecode -s system-product-name | grep -q "20S6003NRI"; then
  log info "Thinkpad T15 detected"

  log info "Installing sof-firmware..."
  pacman -S sof-firmware

  log info "Disabling NVIDIA GPU..."
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
