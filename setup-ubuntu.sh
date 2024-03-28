#!/bin/sh

if [ $(whoami) = 'root' ]; then
    echo 'Dont run this as root'
fi
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt install git konsole build-essential nodejs neovim
git clone https://github.com/krypciak/.nvim ~/.config/nvim
nvim
