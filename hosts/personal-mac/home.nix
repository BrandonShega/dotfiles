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

  # User information
  home.username = "smoochii";
  home.homeDirectory = "/Users/smoochii";
  home.stateVersion = "23.11";

  # Git identity overrides for personal profile
  programs.git.settings.user.name = "Brandon Shega";
  programs.git.settings.user.email = "b.shega@gmail.com";

  # User-level packages
  home.packages = with pkgs; [
    age
    asdf-vm
    bat
    bitwarden-cli
    cmake
    coreutils
    editorconfig-core-c
    eza
    fd
    glib
    gnupg
    gradle
    htop
    imagemagick
    isync
    jq
    lazygit
    mosh
    nodejs
    pass
    peco
    pipx
    pyenv
    ripgrep
    ruby
    rustup
    shellcheck
    tree
    wget
    yazi
  ];
}
