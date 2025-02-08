#!/bin/bash
set -Eeuo pipefail

source <(curl -s https://codeberg.org/f1uff3h/bash/raw/tag/v0.0.7/handlers.sh)

handle_root
handle_errors

cat <<EOT
 ██████████                                                                                                               
░░███░░░░███                                                                                                              
 ░███   ░░███  ██████  █████ █████                                                                                        
 ░███    ░███ ███░░███░░███ ░░███                                                                                         
 ░███    ░███░███████  ░███  ░███                                                                                         
 ░███    ███ ░███░░░   ░░███ ███                                                                                          
 ██████████  ░░██████   ░░█████                                                                                           
░░░░░░░░░░    ░░░░░░     ░░░░░                                                                                            
                                                                                                                          
                                                                                                                          
                                                                                                                          
                                    █████               █████               █████     ███                                 
                                   ░░███               ░░███               ░░███     ░░░                                  
 █████ ███ █████  ██████  ████████  ░███ █████  █████  ███████    ██████   ███████   ████   ██████  ████████              
░░███ ░███░░███  ███░░███░░███░░███ ░███░░███  ███░░  ░░░███░    ░░░░░███ ░░░███░   ░░███  ███░░███░░███░░███             
 ░███ ░███ ░███ ░███ ░███ ░███ ░░░  ░██████░  ░░█████   ░███      ███████   ░███     ░███ ░███ ░███ ░███ ░███             
 ░░███████████  ░███ ░███ ░███      ░███░░███  ░░░░███  ░███ ███ ███░░███   ░███ ███ ░███ ░███ ░███ ░███ ░███             
  ░░████░████   ░░██████  █████     ████ █████ ██████   ░░█████ ░░████████  ░░█████  █████░░██████  ████ █████            
   ░░░░ ░░░░     ░░░░░░  ░░░░░     ░░░░ ░░░░░ ░░░░░░     ░░░░░   ░░░░░░░░    ░░░░░  ░░░░░  ░░░░░░  ░░░░ ░░░░░             
                                                                                                                          
                                                                                                                          
                                                                                                                          
                                 ██████   ███                                           █████     ███                     
                                ███░░███ ░░░                                           ░░███     ░░░                      
  ██████   ██████  ████████    ░███ ░░░  ████   ███████ █████ ████ ████████   ██████   ███████   ████   ██████  ████████  
 ███░░███ ███░░███░░███░░███  ███████   ░░███  ███░░███░░███ ░███ ░░███░░███ ░░░░░███ ░░░███░   ░░███  ███░░███░░███░░███ 
░███ ░░░ ░███ ░███ ░███ ░███ ░░░███░     ░███ ░███ ░███ ░███ ░███  ░███ ░░░   ███████   ░███     ░███ ░███ ░███ ░███ ░███ 
░███  ███░███ ░███ ░███ ░███   ░███      ░███ ░███ ░███ ░███ ░███  ░███      ███░░███   ░███ ███ ░███ ░███ ░███ ░███ ░███ 
░░██████ ░░██████  ████ █████  █████     █████░░███████ ░░████████ █████    ░░████████  ░░█████  █████░░██████  ████ █████
 ░░░░░░   ░░░░░░  ░░░░ ░░░░░  ░░░░░     ░░░░░  ░░░░░███  ░░░░░░░░ ░░░░░      ░░░░░░░░    ░░░░░  ░░░░░  ░░░░░░  ░░░░ ░░░░░ 
                                               ███ ░███                                                                   
                                              ░░██████                                                                    
                                               ░░░░░░                                                                     
EOT

log info "Detecting OS"
if [ -f /etc/os-release ]; then
  source /etc/os-release
else
  log error "OS detection failed"
  exit 1
fi

log info "OS detected: $ID"

log info "Installing dependencies"
case $ID in
fedora)
  dnf install -t git cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++ wl-clipboard openssl openssl-devel nodejs-npm
  ;;
ubuntu)
  apt-get remove -y gnome-shell-extension-ubuntu-dock
  apt-get install -y git cmake cmake g++ pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 gettext librust-openssl-dev libfontconfig-dev fontconfig gcc wl-clipboard curl npm
  ;;
*)
  log error "OS $ID is not supported"
  exit 1
  ;;
esac

userName=$(id -un 1000)

log info "Installing rust"
sudo -u "${userName}" /bin/bash -e -- <<-EOT
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
	/home/${userName}/.cargo/bin/rustup override set stable
	/home/${userName}/.cargo/bin/rustup update stable
EOT

log info "Creating /home/${userName}/bin directory"
sudo -u "${userName}" /bin/bash -e -c "mkdir -p /home/${userName}/bin"

pushd "/home/${userName}/bin/"

log info "Building alacritty"
sudo -u "${userName}" /bin/bash -e -- <<-EOT
  if [ -d /home/${userName}/bin/alacritty ]; then
    pushd alacritty/
    git switch master
    git fetch
    git pull
  else
    pushd alacritty/
    git clone https://github.com/alacritty/alacritty.git
  fi
	/home/${userName}/.cargo/bin/cargo build --release
	mkdir -p ~/.config/alacritty
	curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
	curl -LO --output-dir ~/.config/alacritty https://github.com/catppuccin/alacritty/raw/main/catppuccin-latte.toml
	curl -LO --output-dir ~/.config/alacritty https://github.com/folke/tokyonight.nvim/main/extras/alacritty/tokyonight_moon.toml
	curl -LO --output-dir ~/.config/alacritty https://github.com/folke/tokyonight.nvim/main/extras/alacritty/tokyonight_day.toml
  popd
EOT

tic -xe alacritty,alacritty-direct "/home/${userName}/bin/alacritty/extra/alacritty.info"
infocmp alacritty
cp "/home/${userName}/bin/alacritty/target/release/alacritty" /usr/local/bin
cp "/home/${userName}/bin/alacritty/extra/logo/alacritty-term.svg" /usr/share/pixmaps/Alacritty.svg
desktop-file-install "/home/${userName}/bin/alacritty/extra/linux/Alacritty.desktop"
update-desktop-database

log info "Install rust tools"
sudo -u "${userName}" /bin/bash -e -c "/home/${userName}/.cargo/bin/cargo install zoxide ripgrep fd-find starship nu --locked"

log info "Build neovim"
sudo -u "${userName}" /bin/bash -e -- <<-EOT
  if [ -d /home/${userName}/bin/neovim ]; then
    pushd neovim/
    git switch master
    git fetch
    git pull
  else
    git clone https://github.com/neovim/neovim.git
    pushd neovim/
  fi
	make CMAKE_BUILD_TYPE=RelWithDebInfo
	popd
EOT

pushd neovim/
make install
popd

log info "Installing golang"
sudo -u "${userName}" /bin/bash -e -c "wget https://go.dev/dl/go1.23.6.linux-amd64.tar.gz"
tar -C /usr/local/ -xzf go1.23.6.linux-amd64.tar.gz

log info "Installing go tools"
/usr/local/go/bin/go install github.com/jesseduffield/lazygit@latest
ln -s /usr/local/go/bin/lazygit /usr/local/bin/lazygit

/usr/local/go/bin/go install github.com/junegunn/fzf@latest
ln -s /usr/local/go/bin/fzf /usr/local/bin/fzf

log info "Installing Nerd fonts"
sudo -u "${userName}" /bin/bash -e -- <<-EOT
	mkdir -p ~/.local/share/fonts
	pushd ~/.local/share/fonts
	curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Regular/FiraCodeNerdFont-Regular.ttf
	fc-cache
  popd
EOT

popd

log success "Dev workstation configured successfully"
