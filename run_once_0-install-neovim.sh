# Neovim
rm -rf /tmp/nvim
git clone https://github.com/neovim/neovim.git /tmp/nvim
cd /tmp/nvim || exit
make CMAKE_BUILD_TYPE=Release
sudo make install
