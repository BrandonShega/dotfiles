{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  # Map Neovim config subfiles into ~/.config/nvim with force=true to safely overwrite old generations
  xdg.configFile."nvim/init.lua" = {
    source = ../../config/nvim/init.lua;
    force = true;
  };
  xdg.configFile."nvim/lua" = {
    source = ../../config/nvim/lua;
    force = true;
  };
  xdg.configFile."nvim/lazyvim.json" = {
    source = ../../config/nvim/lazyvim.json;
    force = true;
  };
  xdg.configFile."nvim/stylua.toml" = {
    source = ../../config/nvim/stylua.toml;
    force = true;
  };
}
