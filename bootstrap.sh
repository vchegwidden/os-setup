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
    if command -v $1 2>&1 >/dev/null; then
        echo "  Command $1 found"
        return
    fi

    echo "  Installing $1"
    if brew list $1 &>/dev/null; then
        echo "    ${1} is already installed via homebrew"
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
    system_name=$(uname | tr '[:upper:]' '[:lower:]')
    new_key_created=false

    if [[ ! -d "${HOME}/.ssh" ]]; then
        echo "Create .ssh directory"
        mkdir ~/.ssh
    fi
    if [[ ! -f "${HOME}/.ssh/github_com" ]]; then
        echo "Create github key. Remember to add it to github.com"
        ssh-keygen -t ed25519 -C "Github key for ${distro} ${hostname}" -f ~/.ssh/github_com -q -N ""
        echo " "
        cat ~/.ssh/github_com.pub
        echo ""
        new_key_created=true
    fi
    if [[ ! -f "${HOME}/.ssh/gitlab_com" ]]; then
        echo "Create gitlab key. Remember to add it to gitlab.com"
        ssh-keygen -t ed25519 -C "Gitlab key for ${distro} ${hostname}" -f ~/.ssh/gitlab_com -q -N ""
        echo " "
        cat ~/.ssh/gitlab_com.pub
        echo ""
        new_key_created=true
    fi

    if $new_key_created; then
        if [[ "$system_name" == "darwin" ]]; then
        open https://github.com/settings/keys
        else
        xdg-open https://github.com/settings/keys >/dev/null 2>&1
        fi

        read -n 1 -s -r -p "Press any key to continue once the key has been added to Github..."
        echo " "
    fi
}

install_homebrew() {
    # install homebrew
    if ! command -v brew 2>&1 >/dev/null
    then
        echo "Install Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo ""

        #echo >> $HOME/.bashrc
        test -d /opt/homebrew && eval "$(/opt/homebrew/bin/brew shellenv)"
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
    fi
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

if [[ ! -d "${HOME}/dotfiles" ]]; then
    echo "Cloning dotfiles repo"
    ssh-agent bash -c 'ssh-add ${HOME}/.ssh/github_com; git clone git@github.com:vchegwidden/dotfiles.git ~/dotfiles'
    #git clone git@github.com:vchegwidden/dotfiles.git ~/dotfiles
    echo ""
fi

if [[ ! -d "${HOME}/Dev" ]]; then
    echo "Create Dev Directory"
    mkdir ~/Dev
    echo ""
fi

# Install homebrew
install_homebrew

# Install common brews used by all systems
source ${HOME}/dotfiles/setup/homebrew.sh

# MacOS apps
if [[ "$system_name" == "darwin" ]]; then
    source ${HOME}/dotfiles/setup/macos.sh
fi

if [[ "$system_name" == "linux" ]]; then
    source /etc/os-release
    echo "PRETTY_NAME is $PRETTY_NAME"
    # Name = Fedora Linux 41 (KDE Plasma)
    # Name = Arch Linux

    if [[ "$system_name" == "Arch Linux" ]]; then
        source ${HOME}/dotfiles/setup/omarchy.sh
    fi

    echo ""
fi

source ${HOME}/dotfiles/setup/symlinks.sh

# Install NeoVim starter config
#git clone git@github.com:vchegwidden/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim

echo ""
if ! command -v omarchy-show-done 2>&1 >/dev/null; then
    echo "Done"
else
    omarchy-show-done
fi
