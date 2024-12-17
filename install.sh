set +x

GITURL=https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main

# download eza keys
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

# install stuffs
apt update && apt install -y \
  net-tools \
  git \
  curl \
  nmap \
  wget \
  bat \
  tmux \
  nano \
  eza

# Install starship
wget https://starship.rs/install.sh -o /tmo/starship-install.sh
bash /tmp/starship-install.md --yes

# Download config files
mkdir -p ~/.ssh
mkdir -p ~/.config
wget $GITURL/.ssh/config -o ~/.ssh/config
wget $GITURL/.config/starship.toml -o ~/.config/starship.toml
wget $GITURL/tmux/lite/.tmux.conf -o ~/.tmux.conf
wget $GITURL/bash/.bashrc -o ~/.bash_addons

# Download custom aliases and create a link for bash
wget $GITURL/bash/.aliases -o ~/.aliases
#rm ~/.bash_aliases
ln -s ~/.aliases ~/.bash_aliases
ln -s ~/.aliases ~/.config/.user_aliases

# add bash_addons loading line
if ! grep -Fq "~/.bash_addons" ~/.bashrc
then
    echo ". ~/.bash_addons" >> ~/.bashrc
fi

