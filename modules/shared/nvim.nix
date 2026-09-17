{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
  ];

  # Declaratively install Neovim configuration into ~/.config/nvim
  xdg.configFile."nvim".source = ../../config/nvim;
}
