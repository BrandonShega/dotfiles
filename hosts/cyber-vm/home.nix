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

  # User information for Kali VM
  home.username = "kali";
  home.homeDirectory = "/home/kali";
  home.stateVersion = "23.11";

  # Git identity overrides for VM profile
  programs.git.settings.user.name = "Kali User";
  programs.git.settings.user.email = "kali@smoochii.dev";

  # User-level packages (minimal, as Kali has most security tools pre-installed)
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
