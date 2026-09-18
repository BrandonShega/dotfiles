{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    roboto
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
    nerd-fonts.monaspace
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Enable fontconfig for user-level font rendering
  fonts.fontconfig.enable = true;
}
