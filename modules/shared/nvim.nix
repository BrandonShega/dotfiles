{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  # Map Neovim config subfiles into ~/.config/nvim while keeping the directory writable for lazy-lock.json
  xdg.configFile."nvim/init.lua".source = ../../config/nvim/init.lua;
  xdg.configFile."nvim/lua".source = ../../config/nvim/lua;
  xdg.configFile."nvim/lazyvim.json".source = ../../config/nvim/lazyvim.json;
  xdg.configFile."nvim/stylua.toml".source = ../../config/nvim/stylua.toml;
}
