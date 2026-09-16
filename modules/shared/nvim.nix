{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/Documents/dev/dotfiles";
in
{
  home.packages = with pkgs; [
    neovim
  ];

  # Declaratively symlink your Neovim configuration directory
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/nvim";
}
