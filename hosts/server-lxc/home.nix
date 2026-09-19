{ config, pkgs, ... }:

{
  imports = [
    ../../modules/shared/zsh.nix
    ../../modules/shared/git.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/starship.nix
    ../../modules/shared/ssh.nix
    ../../modules/shared/vim.nix
  ];

  # User information for Server LXC / Headless nodes
  home.username = "smoochii";
  home.homeDirectory = "/home/smoochii";
  home.stateVersion = "23.11";
  home.backupFileExtension = "backup";

  # Git identity overrides
  programs.git.settings.user.name = "Brandon Shega";
  programs.git.settings.user.email = "b.shega@gmail.com";

  # Essential lightweight CLI packages (no fonts or heavy dev compilers)
  home.packages = with pkgs; [
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
