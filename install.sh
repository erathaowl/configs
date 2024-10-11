set +x

GITURL=https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main

# install stuffs
apt update && apt install -y \
  net-tools \
  git \
  curl \
  nmap \
  wget \
  bat \
  tmux \
  nano

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Download config files
mkdir -p ~/.ssh
mkdir -p ~/.config
wget $GITURL/.ssh/config -o ~/.ssh/config
wget $GITURL/.config/starship.toml -o ~/.config/starship.toml
wget $GITURL/tmux/lite/.tmux.conf -o ~/.tmux.conf
wget $GITURL/bash/.bashrc -o ~/.bash_addons
wget $GITURL/bash/.bash_aliases -o ~/.bash_aliases

# add bash_addons loading line
if grep -Fxq ".bash_addons" ~/.bashrc
then
    :
else
    echo ". ~/bash_addons" >> ~/.bashrc
fi

