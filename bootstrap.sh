#!/usr/bin/env bash

mas_install() {
  echo "  Installing $1 $2"
  if mas list | grep $1 &>/dev/null; then
    echo "    ${2} is already installed"
  else
    mas install $1 &&
      echo "    $2 is installed"
  fi
}

flatpak_install() {
  echo "  Installing $1"
  if flatpak list $1 &>/dev/null; then
    ehco "    ${1} is already installed"
  else
    sudo flatpak install $1 &&
      ehco "    $1 is installed"
  fi
}

brew_install() {
  echo "  Installing $1"
  if brew list $1 &>/dev/null; then
    echo "    ${1} is already installed"
  else
    brew install $1 &&
      echo "    $1 is installed"
  fi
}

brew_install_cask() {
  echo "  Installing cask $1"
  if brew list $1 &>/dev/null; then
    echo "    ${1} is already installed"
  else
    brew install --cask $1 &&
      echo "    $1 is installed"
  fi
}

pkg_install() {
  local distro
  local cmd
  local usesudo
  declare -A pkgmgr

  pkgmgr=(
    [arch]="pacman -S --noconfirm"
    [alpine]="apk add --no-cache"
    [debian]="apt-get install -y"
    [ubuntu]="apt-get install -y"
    [fedora]="dnf install"
    [redhat]="yum install"
    [suse]="zypp"
  )

  distro=$(cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos|arch|alpine|fedora)' | uniq)
  cmd="${pkgmgr[$distro]}"
  [[ ! $cmd ]] && return 1
  if [[ $1 ]]; then
    [[ ! $EUID -eq 0 ]] && usesudo=sudo
    echo installing packages command: $usesudo $cmd $@
    $usesudo $cmd $@
  else
    echo $cmd
  fi
}

create_ssh_keys() {
  distro=$(cat /etc/os-release | tr [:upper:] [:lower:] | grep -Poi '(debian|ubuntu|red hat|centos|arch|alpine|fedora)' | uniq)

  if [[ ! -d "${HOME}/.ssh" ]]; then
    echo "Create .ssh directory"
    mkdir ~/.ssh
  fi
  if [[ ! -f "${HOME}/.ssh/github_com" ]]; then
    echo "Create github key. Remember to add it to github.com"
    ssh-keygen -t ed25519 -C "Github key for ${distro} ${hostname}" -f ~/.ssh/github_com -q -N ""
    echo " "
    cat ~/.ssh/github_com.pub
    echo " "
  fi
  if [[ ! -f "${HOME}/.ssh/gitlab_com" ]]; then
    echo "Create gitlab key. Remember to add it to gitlab.com"
    ssh-keygen -t ed25519 -C "Gitlab key for ${distro} ${hostname}" -f ~/.ssh/gitlab_com -q -N ""
    echo " "
    cat ~/.ssh/gitlab_com.pub
    echo " "
  fi

  echo "Press any key to continue one the github key has been added"
  read
}

###########################
# MAIN
###########################

# Fail on any error
set -e

is_server=false
if [[ $variable ]]; then
  is_server=$1
fi
echo "Checking if system is a server"
echo "  is_server=${is_server}"
echo ""

system_name=$(uname | tr '[:upper:]' '[:lower:]')

# Create ssh keys for github and gitlab
create_ssh_keys

echo "Cloning dotfiles repo"
git clone git@github.com:vchegwidden/dotfiles.git ~/dotfiles

# Install Xcode
# if [[ "$system_name" == "darwin" ]]; then
#     echo "### Install Xcode"
#     softwareupdate --install-rosetta
#     xcode-select --install
#     echo ""
# fi

use_homebrew="Y"

if [[ "$system_name" != "darwin" ]]; then
  echo "Do you want to use homebrew to install applications? [Y]yes or [N]No"
  read use_homebrew
  # convert to upper
  use_homebrew=$(echo $use_homebrew | tr '[:lower:]' '[:upper:]')
fi

if [[ "$use_homebrew" = "Y" ]]; then
  echo "Using homebrew to install applications."
elif [[ "$use_homebrew" = "N" ]]; then
  echo "Using OS package manager to install applications."
else
  echo "Invalid input. Must be Y or N."
  exit 1
fi

# install homebrew
if [[ "$use_homebrew" = "Y" ]]; then
  if ! command -v brew 2>&1 >/dev/null; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo ""

    #echo >> $HOME/.bashrc
    #echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc
    #eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.bashrc
  else
    echo "Homebrew already installed. Continuing.."
  fi
fi

# Install brews

# MacOS brew apps
if [[ "$system_name" == "darwin" ]]; then
  echo "Install MacOS specific"
  brew_install kdoctor
  brew_install mas
  echo ""
fi

# MacOS brew casks
if [[ "$system_name" == "darwin" ]]; then
  echo "Install casks"
  brew_install_cask firefox
  brew_install_cask wireshark
  brew_install_cask onedrive
  brew_install_cask jetbrains-toolbox
  brew_install_cask temurin
  brew_install_cask temurin@21
  brew_install_cask vlc
  brew_install_cask ghostty
  brew_install_cask karabiner-elements
  brew_install_cask keepassxc
  brew_install_cask visual-studio-code
  brew_install_cask obsidian
  brew_install_cask font-hack-nerd-font
  brew_install_cask font-jetbrains-mono-nerd-font
  brew_install_cask podman-desktop
  brew_install_cask slack
  #    brew_install_cask virtualbox
  brew_install_cask inkscape
  brew_install_cask gimp
  brew_install_cask brave-browser
  brew_install_cask mullvadvpn
  brew_install_cask rustdesk
  echo ""

  # install mac app store apps
  echo "Mac app store apps"
  mas_install "Xcode" 497799835
  #mas_install "DaVinci Resolve" 571213070
  mas_install "Tailscale" 1475387142
  echo ""
fi

# MacOs defaults
if [[ "$system_name" == "darwin" ]]; then
  echo "Setting MacOs defaults"
  # defaults read com.apple.finder
  # defaults read NSGlobalDomain KeyRepeat
  # defaults read NSGlobalDomain InitialKeyRepeat

  # defaults write -g ApplePressAndHoldEnabled -bool false
  # defaults write -g InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
  # defaults write -g KeyRepeat -int 1 # normal minimum is 2 (30 ms)
  # defaults write NSGlobalDomain InitialKeyRepeat -int 10 # normal minimum is 15 (225 ms)
  # defaults write NSGlobalDomain KeyRepeat -int 1 # normal minimum is 2 (30 ms)
fi

if [[ "$system_name" == "linux" ]]; then
  echo "I am linux"
  echo "$OSTYPE"
  #Fedora = linux-gnu

  source /etc/os-release
  echo $PRETTY_NAME
  # Name = Fedora Linux 41 (KDE Plasma)

  # TODO check if distro is fedora

fi

echo "Setting symlinks"
#ln -sf $HOME/dotfiles/zsh/.zshrc "$HOME/.zshrc"
#ln -sf $HOME/dotfiles/zsh/.zprofile "$HOME/.zprofile"
#ln -sf $HOME/dotfiles/ssh/config "$HOME/.ssh/config"
#ln -sf $HOME/dotfiles/git/config "$HOME/.gitconfig"
#ls -sf $HOME/dotfiles/ideavim/config "$HOME/.ideavimrc"
#ln -sf $HOME/dotfiles/karabiner/karabiner.json $HOME/.config/karabiner/karabiner.json
#ln -sf $HOME/dotfiles/ghostty/config $HOME/.config/ghostty/config
#sudo ln -s $(where podman) /usr/local/bin/docker

# NuShell config
if [[ "$system_name" == "darwin" ]]; then
  ln -sf $HOME/dotfiles/nushell/env.nu "/Users/vince/Library/Application Support/nushell/env.nu"
  ln -sf $HOME/dotfiles/nushell/config.nu "/Users/vince/Library/Application Support/nushell/config.nu"
fi

# Install NeoVim starter config
#git clone git@github.com:vchegwidden/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

echo ""
echo "Done"
echo ""
