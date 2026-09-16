{ config, pkgs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/Documents/dev/dotfiles";
in
{
  # Symlink Ghostty configuration
  xdg.configFile."ghostty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/ghostty";

  # Symlink Alacritty configuration
  xdg.configFile."alacritty".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/config/alacritty";
}
