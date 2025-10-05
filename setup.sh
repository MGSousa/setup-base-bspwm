#!/bin/bash
# shellcheck disable=SC2016,SC1091

set -o pipefail

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
      echo -e "\n\e[0;31m\033[1m $msg \033[0m\e[0m"
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

  if ! command -v brew &>/dev/null; then
    # install brew for additional dependencies
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' | tee -a "$HOME/.bashrc" "$HOME/.zshrc"

    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  if ! command -v fnm gum btop &>/dev/null; then
    brew install fnm gum btop
    echo 'eval "$(fnm env --use-on-cd --shell bash)"' >>"$HOME/.bashrc"
    echo 'eval "$(fnm env --use-on-cd --shell zsh)"' >>"$HOME/.zshrc"

    eval "$(fnm env --use-on-cd --shell bash)"
  fi

  _e "Installing necessary packages for the environment..." info
  if
    ! sudo apt install -y \
      git curl flatpak net-tools zsh figlet lolcat kitty rofi feh xclip ranger dunst \
      scrot scrub cmatrix htop python3-pip tty-clock fzf bat flameshot shellcheck \
      distrobox vim wmname zsh-syntax-highlighting zsh-autosuggestions
  then
    _e "Failed to install some packages!" error
    exit 1
  fi

  _e "Setup Rust" info
  curl https://sh.rustup.rs -sSf | bash
  . "$HOME/.cargo/env"

  _e "Setup neovim" info
  set -e
  curl -sLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  sudo mkdir -p /opt/nvim && sudo install -D nvim-linux-x86_64.appimage /opt/nvim/bin/nvim
  echo 'export PATH=$PATH:/opt/nvim/bin' >>"$HOME/.zshrc"
  set +e

  _e "Starting installation of necessary dependencies for the environment..." info
  sleep 0.5

  _e "Installing necessary dependencies for rust and bspwm..." info
  sleep 2
  if
    ! sudo apt install -y \
      build-essential libssl-dev pkg-config libfontconfig-dev \
      libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev \
      libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev libuv1-dev
  then
    _e "Failed to install some dependencies for bspwm!" error
    exit 1
  fi

  _e "Install cargo-update, ripgrep, alacritty" info
  if ! cargo install cargo-update ripgrep alacritty; then
    _e "Failed to install some rust dependencies, check errors above" error
    exit 1
  fi

  _e "Setup NodeJS" info
  mapfile versions < <(fnm ls-remote | tail -50)
  NODE_VERSION=$(
    gum choose --cursor.foreground="112" --height=20 --header="Which Node Version to install?" "${versions[@]}"
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
    fi
  )

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    _e "Installing Oh My Zsh and Powerlevel10k for user $user..." info
    sleep 2
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom}/themes/powerlevel10k"; then
      _e "Failed to install Oh My Zsh and Powerlevel10k for user $user!" error
      exit 1
    fi
  fi

  _e "Configuring wallpaper and fonts..." info
  sleep 2
  mkdir -p ~/Wallpapers
  cp -rv "$dir/fonts/"* "$fdir"
  cp -rv "$dir/wallpapers/"* ~/Wallpapers

  _e "Set configuration files..." info
  sleep 2
  cp -rv "$dir/configs/"* ~/.config/
  cp -v "$dir/.zshrc" ~/.zshrc
  cp -v "$dir/.p10k.zsh" ~/.p10k.zsh

  _e "Configuring scripts..." info
  sleep 2
  sudo cp -v "$dir/scripts/whichSystem.py" /usr/local/bin/
  cp -rv "$dir/scripts/"*.sh ~/.config/polybar/shapes/scripts/
  touch ~/.config/polybar/shapes/scripts/target

  _e "Configuring necessary permissions and symbolic links..." info
  sleep 2
  chmod -R +x ~/.config/bspwm/
  chmod +x ~/.config/polybar/launch.sh ~/.config/polybar/shapes/scripts/*
  sudo chmod +x /usr/local/bin/whichSystem.py /usr/local/share/zsh/site-functions/_bspc

  _e "Running Post installation scripts" info
  "$dir/scripts/determine_interface.sh"
  sleep 2

  REPLY=$(
    gum confirm \
      --selected.background="160" --prompt.foreground="#7571F9" --show-output \
      "Environment configured! It is necessary to restart the system. Do you want to restart the system now?"
  )
  if [ "$REPLY" = "Yes" ]; then
    _e "Restarting the system..."
    sudo shutdown -r now
  else
    _e "Restart cancelled, please restart it later"
  fi
fi
