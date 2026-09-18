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
    ../../modules/shared/fonts.nix
  ];

  # User information for Linux
  home.username = "smoochii";
  home.homeDirectory = "/home/smoochii";
  home.stateVersion = "23.11";

  # Git identity overrides
  programs.git.settings.user.name = "Brandon Shega";
  programs.git.settings.user.email = "b.shega@gmail.com";

  # User-level packages for Linux
  home.packages = with pkgs; [
    age
    asdf-vm
    bat
    bitwarden-cli
    cmake
    eza
    fd
    gnupg
    htop
    imagemagick
    jq
    lazygit
    nodejs
    ripgrep
    ruby
    rustup
    shellcheck
    tree
    wget
    yazi

    # Build tools for compiling code (replacing build-essential)
    gnumake
    gcc
    binutils
  ];
}
