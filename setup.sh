#!/bin/bash
# shellcheck disable=SC2016

set -o pipefail

# Global variables
dir=$(pwd)
fdir="$HOME/.local/share/fonts"
user=$(whoami)

trap _int INT

_int() {
  _e "Exiting..." error
  exit 1
}

_e() {
  local msg=$1
  local tpe=$2

  if [ "$tpe" = "info" ]; then
    gum style --foreground="270" --border=rounded --border-foreground="270" --bold "[*] $msg"
  elif [ "$tpe" = "error" ]; then
    if command -v gum &>/dev/null; then
      gum style --foreground="160" --border=rounded --border-foreground="160" --bold "[-] $msg"
    else
      echo -e "\n\e[0;33m\033[1m $msg \033[0m\e[0m"
    fi
  else
    gum style --foreground="120" --border=rounded --border-foreground="120" --bold "[+] $msg"
  fi
}

if [ "$user" = "root" ]; then
  _e "You should not run this script as the root user!" error
  exit 1
else
  sudo apt update

  # install brew for additional dependencies
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | tee -a "$HOME/.bashrc" "$HOME/.zshrc"

  brew install fnm gum
  echo 'eval "$(fnm env --use-on-cd --shell bash)"' >>"$HOME/.bashrc"
  echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >>"$HOME/.zshrc"

  _e "Installing necessary packages for the environment..." info
  if
    ! sudo apt install -y \
      git curl flatpak net-tools zsh figlet lolcat kitty rofi feh xclip ranger dunst alacritty \
      scrot scrub cmatrix htop python3-pip tty-clock fzf bat flameshot shellcheck \
      distrobox vim wmname
  then
    _e "Failed to install some packages!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Setup neovim" info
  set -e
  curl -sSLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  sudo mkdir -p /opt/nvim && sudo install -D nvim-linux-x86_64.appimage /opt/nvim/bin/nvim
  echo 'export PATH=$PATH:/opt/nvim/bin' >>"$HOME/.zshrc"
  set +e

  _e "Starting installation of necessary dependencies for the environment..." info
  sleep 0.5

  _e "Installing necessary dependencies for bspwm..." info
  sleep 2
  if
    ! sudo apt install -y \
      build-essential \
      libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev \
      libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev libuv1-dev
  then
    _e "Failed to install some dependencies for bspwm!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Setup Node" info
  # shellcheck disable=SC2046
  NODE_VERSION=$(
    gum choose --cursor.foreground="112" --height=20 --header="Which Node Version to install?" \
      $(fnm ls-remote | tail -50)
  )
  if [ -n "${NODE_VERSION}" ]; then
    fnm i "${NODE_VERSION}" && fnm default "${NODE_VERSION}"
  fi

  _e "Installing necessary dependencies for polybar..." info
  sleep 2
  if
    ! sudo apt install -y \
      cmake cmake-data pkg-config python3-sphinx python3-xcbgen \
      libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev libxcb-composite0-dev \
      xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev \
      libasound2-dev libpulse-dev libjsoncpp-dev libcurl4-openssl-dev libnl-genl-3-dev
  then
    _e "Failed to install some dependencies for polybar!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Installing necessary dependencies for picom..." info
  sleep 2
  if
    ! sudo apt install -y \
      meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
      libxcb-render-util0-dev libxcb-render0-dev libxcb-randr0-dev libxcb-composite0-dev \
      libxcb-image0-dev libxcb-present-dev libxcb-xinerama0-dev libpixman-1-dev \
      libdbus-1-dev libconfig-dev libgl1-mesa-dev libegl1-mesa-dev libpcre2-dev libpcre3-dev \
      libevdev-dev uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev
  then
    _e "Failed to install some dependencies for picom!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Installing bspwm..." info
  sleep 2
  (
    if [ ! -d bspwm ]; then
      git clone https://github.com/baskerville/bspwm.git
    fi
    cd bspwm && make -j"$(nproc)"

    if ! sudo make install; then
      _e "Failed to install bspwm!" error
      exit 1
    fi

    _e "Done"
    sleep 1.5
  )

  _e "Installing sxhkd..." info
  sleep 2
  (
    if [ ! -d sxhkd ]; then
      git clone https://github.com/baskerville/sxhkd
    fi
    cd sxhkd && make -j"$(nproc)"
    if ! sudo make install; then
      _e "Failed to install sxhkd!" error
      exit 1
    else
      _e "Done"
      sleep 1.5
    fi
  )

  _e "Installing polybar..." info
  sleep 2
  (
    if [ ! -d polybar ]; then
      git clone --recursive https://github.com/polybar/polybar
    fi
    cd polybar && mkdir -p build
    cd build && cmake ..
    make -j"$(nproc)"

    if ! sudo make install; then
      _e "Failed to install polybar!" error
      exit 1
    else
      _e "Done"
      sleep 1.5
    fi
  )

  _e "Installing picom..." info
  sleep 2
  (
    if [ ! -d picom ]; then
      git clone https://github.com/ibhagwan/picom.git
    fi
    cd picom && git submodule update --init --recursive
    meson --buildtype=release . build
    ninja -C build
    if ! sudo ninja -C build install; then
      _e "Failed to install picom!" error
      exit 1
    else
      _e "Done"
      sleep 1.5
    fi
  )

  _e "Installing Oh My Zsh and Powerlevel10k for user $user..." info
  sleep 2
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"; then
    _e "Failed to install Oh My Zsh and Powerlevel10k for user $user!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Installing Oh My Zsh and Powerlevel10k for user root..." info
  sleep 2
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  if ! sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k; then
    _e "Failed to install Oh My Zsh and Powerlevel10k for user root!" error
    exit 1
  else
    _e "Done"
    sleep 1.5
  fi

  _e "Starting configuration of fonts, wallpaper, configuration files, .zshrc, .p10k.zsh, and scripts..." info
  sleep 0.5

  _e "Configuring fonts..." info
  sleep 2
  if [[ -d "$fdir" ]]; then
    cp -rv $dir/fonts/* $fdir
  else
    mkdir -p $fdir
    cp -rv $dir/fonts/* $fdir
  fi
  _e "Done"
  sleep 1.5

  _e "Configuring wallpaper..." info
  sleep 2
  if [[ -d "$HOME/Wallpapers" ]]; then
    cp -rv "$dir/wallpapers/*" ~/Wallpapers
  else
    mkdir ~/Wallpapers
    cp -rv "$dir/wallpapers/*" ~/Wallpapers
  fi
  _e "Done"
  sleep 1.5

  _e "Set configuration files..." info
  sleep 2
  cp -rv "$dir/configs/*" ~/.config/
  _e "Done"
  sleep 1.5

  _e "Configuring the .zshrc and .p10k.zsh files..." info
  sleep 2
  cp -v "$dir/.zshrc" ~/.zshrc
  sudo ln -sfv ~/.zshrc /root/.zshrc
  cp -v "$dir/.p10k.zsh" ~/.p10k.zsh
  sudo ln -sfv ~/.p10k.zsh /root/.p10k.zsh
  _e "Done"
  sleep 1.5

  _e "Configuring scripts..." info
  sleep 2
  sudo cp -v "$dir/scripts/whichSystem.py" /usr/local/bin/
  cp -rv "$dir/scripts/*.sh" ~/.config/polybar/shapes/scripts/
  touch ~/.config/polybar/shapes/scripts/target
  _e "Done"
  sleep 1.5

  _e "Configuring necessary permissions and symbolic links..." info
  sleep 2
  chmod -R +x ~/.config/bspwm/
  chmod +x ~/.config/polybar/launch.sh ~/.config/polybar/shapes/scripts/*
  sudo chmod +x /usr/local/bin/whichSystem.py /usr/local/share/zsh/site-functions/_bspc
  sudo chown root:root /usr/local/share/zsh/site-functions/_bspc
  sudo mkdir -p /root/.config/polybar/shapes/scripts/
  sudo touch /root/.config/polybar/shapes/scripts/target
  sudo ln -sfv ~/.config/polybar/shapes/scripts/target /root/.config/polybar/shapes/scripts/target

  _e "Done"
  sleep 1.5

  _e "Running Post installation scripts" info
  "$dir/scripts/determine_interface.sh"
  sleep 2

  _e "Environment configured" info
  sleep 1.5

  REPLY=$(
    gum confirm \
      --selected.background="160" --prompt.foreground="#7571F9" --show-output \
      "It is necessary to restart the system. Do you want to restart the system now?"
  )
  if [ "$REPLY" = "Yes" ]; then
    _e "Restarting the system..."
    sleep 1
    sudo reboot
  else
    _e "Restart cancelled, please restart it later"
  fi
fi
