#!/bin/bash
set -Eeuo pipefail

source <(curl -s https://codeberg.org/f1uff3h/bash/raw/tag/v0.0.7/handlers.sh)

handle_root
handle_errors

cat <<EOT
  ███                      █████              ████  ████                    
 ░░░                      ░░███              ░░███ ░░███                    
 ████  ████████    █████  ███████    ██████   ░███  ░███                    
░░███ ░░███░░███  ███░░  ░░░███░    ░░░░░███  ░███  ░███                    
 ░███  ░███ ░███ ░░█████   ░███      ███████  ░███  ░███                    
 ░███  ░███ ░███  ░░░░███  ░███ ███ ███░░███  ░███  ░███                    
 █████ ████ █████ ██████   ░░█████ ░░████████ █████ █████                   
░░░░░ ░░░░ ░░░░░ ░░░░░░     ░░░░░   ░░░░░░░░ ░░░░░ ░░░░░                    
                                                                            
                                                                            
                                                                            
    ██████  ████             █████                        █████             
   ███░░███░░███            ░░███                        ░░███              
  ░███ ░░░  ░███   ██████   ███████   ████████   ██████   ░███ █████  █████ 
 ███████    ░███  ░░░░░███ ░░░███░   ░░███░░███ ░░░░░███  ░███░░███  ███░░  
░░░███░     ░███   ███████   ░███     ░███ ░███  ███████  ░██████░  ░░█████ 
  ░███      ░███  ███░░███   ░███ ███ ░███ ░███ ███░░███  ░███░░███  ░░░░███
  █████     █████░░████████  ░░█████  ░███████ ░░████████ ████ █████ ██████ 
 ░░░░░     ░░░░░  ░░░░░░░░    ░░░░░   ░███░░░   ░░░░░░░░ ░░░░ ░░░░░ ░░░░░░  
                                      ░███                                  
                                      █████                                 
                                     ░░░░░                                  
EOT

log info "Detecting OS"
if [ -f /etc/os-release ]; then
  source /etc/os-release
else
  log error "OS detection failed"
  exit 1
fi

log info "OS detected: $ID"

case $ID in
ubuntu)
  log info "Installing flatpak"
  apt-get install -y flatpak gnome-software-plugin-flatpak
  ;;
*)
  log error "OS $ID is not supported"
  ;;
esac

userName=$(id -un 1000)

log info "Adding flathub remote"
sudo -u "${userName}" /bin/bash -e -c "flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"

log info "Installing flatpaks"
sudo -u "${userName}" /bin/bash -e -c "flatpak install -y --user flathub com.github.tchx84.Flatseal ca.desrt.dconf-editor com.bitwarden.desktop com.brave.Browser com.jgraph.drawio.desktop com.mattjakeman.ExtensionManager com.rustdesk.RustDesk me.proton.Mail org.localsend.localsend_app"
