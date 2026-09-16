{ config, pkgs, ... }:

{
  imports = [
    ../../modules/shared/zsh.nix
    ../../modules/shared/git.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/starship.nix
    ../../modules/shared/ssh.nix
    ../../modules/shared/nvim.nix
    ../../modules/shared/ghostty.nix
  ];

  # User information
  home.username = "smoochii";
  home.homeDirectory = "/home/smoochii";
  home.stateVersion = "23.11";

  # Git identity overrides
  programs.git.settings.user.name = "Brandon Shega";
  programs.git.settings.user.email = "b.shega@gmail.com";

  # User-level packages
  home.packages = with pkgs; [
    age
    bat
    eza
    fd
    jq
    lazygit
    ripgrep
    tree
    wget
  ];
}
