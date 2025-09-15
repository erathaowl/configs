#!/bin/bash

USER_HOME=$(eval echo "~$SUDO_USER")

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo'."
    exit 1
fi


# Select interface
read -rp "Use whiptail, dialog, or text-only? [w/d/t]: " choice
case "$choice" in
    w) UI="whiptail" ;;
    d) UI="dialog" ;;
    t) UI="text" ;;
    *) echo "Invalid choice"; exit 1 ;;
esac


# Ask user confirm before install
confirm_install() {
    local pkg="$1"
    case "$UI" in
        text)
            read -rp "Install $pkg? [y/N]: " ans
            [[ "$ans" =~ ^[Yy]$ ]]
            ;;
        whiptail|dialog)
            $UI --yesno "Install $pkg?" 10 60
            return $?  # 0 = Yes, 1 = No
            ;;
    esac
}


set +x

GITURL=https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main

# install stuffs
apt update && apt install -y \
  net-tools \
  htop \
  git \
  curl \
  nmap \
  wget \
  bat \
  tmux \
  nano \
  renameutils

# Install eza
if confirm_install "eza"; then
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt update && apt install -y eza
fi

# Install starship
if confirm_install "starship"; then
    wget https://starship.rs/install.sh -O /tmo/starship-install.sh
    bash /tmp/starship-install.md --yes
fi


# install customizations:
if confirm_install "shell customizations"; then

    # Download config files
    mkdir -p ~/.config
    mkdir -p $USER_HOME/.config
    mkdir -p $USER_HOME/.ssh


    wget $GITURL/.ssh/config -O $USER_HOME/.ssh/config
    wget $GITURL/.config/starship.toml -O $USER_HOME/.config/starship.toml
    wget $GITURL/tmux/lite/.tmux.conf -O $USER_HOME/.tmux.conf
    wget $GITURL/bash/.bash_addons -O $USER_HOME/.bash_addons

    # Download custom aliases and create a link for bash for both user and root
    wget $GITURL/bash/.aliases -O ~/.config/.user_aliases
    wget $GITURL/bash/.aliases -O $USER_HOME/.config/.user_aliases

    ln -sf ~/.config/.user_aliases ~/.bash_aliases
    ln -sf $USER_HOME/.config/.user_aliases $USER_HOME/.bash_aliases

    # add bash_addons loading line
    if ! grep -Fq "~/.bash_addons" $USER_HOME/.bashrc; then
        echo "" >> $USER_HOME/.bashrc
        echo ". ~/.bash_addons" >> $USER_HOME/.bashrc
    fi

    chown -R $SUDO_USER: $USER_HOME/.ssh
    chown -R $SUDO_USER: $USER_HOME/.config
    chown $SUDO_USER: $USER_HOME/.bash_addons
    chown $SUDO_USER: $USER_HOME/.bash_aliases
    chown $SUDO_USER: $USER_HOME/.tmux.conf

fi
