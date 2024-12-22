if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use 'sudo'."
    exit 1
fi

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
  nano


# download eza keys
if whiptail --yesno "Install eza?" 10 60; then
    mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    apt update && apt install -y eza
fi

# Install starship
if whiptail --yesno "Install starship?" 10 60; then
    wget https://starship.rs/install.sh -o /tmo/starship-install.sh
    bash /tmp/starship-install.md --yes
fi

# Download config files
mkdir -p ~/.ssh
mkdir -p ~/.config

wget $GITURL/.ssh/config -o ~/.ssh/config
wget $GITURL/.config/starship.toml -o ~/.config/starship.toml
wget $GITURL/tmux/lite/.tmux.conf -o ~/.tmux.conf
wget $GITURL/bash/.bash_addons -o ~/.bash_addons

# Download custom aliases and create a link for bash
wget $GITURL/bash/.aliases -o ~/.config/.aliases
#if [ ! -f /.bash_aliases ]; then
  #rm ~/.bash_aliases
#fi
ln -s ~/.config/.aliases ~/.bash_aliases
ln -s ~/.config/.aliases ~/.config/.user_aliases

# add bash_addons loading line
if ! grep -Fq "~/.bash_addons" ~/.bashrc
then
    echo ". ~/.bash_addons" >> ~/.bashrc
fi

