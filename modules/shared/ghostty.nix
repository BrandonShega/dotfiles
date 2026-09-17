{ config, pkgs, ... }:

{
  # Symlink Ghostty configuration into ~/.config/ghostty
  xdg.configFile."ghostty".source = ../../config/ghostty;

  # Symlink Alacritty configuration into ~/.config/alacritty
  xdg.configFile."alacritty".source = ../../config/alacritty;
}
