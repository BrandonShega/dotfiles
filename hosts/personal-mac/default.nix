{ pkgs, ... }:

{
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/wm.nix
  ];

  # Hostname & Primary User Configuration
  networking.hostName = "smoochii-mac";
  system.primaryUser = "smoochii";

  # Configure user details
  users.users.smoochii = {
    home = "/Users/smoochii";
    shell = pkgs.zsh;
  };

  # Declarative Homebrew integration
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "zap";
      autoUpdate = true;
      upgrade = true;
    };

    taps = [
      "heroku/brew"
    ];

    brews = [
      "libproxy"
      "minicom"
      "mpc"
      "putty"
      "subversion"
      "the_silver_searcher"
      "unbound"
      "yadm"
    ];

    casks = [
      "1password-cli"
      "alacritty"
      "bitwarden"
      "discord"
      "ghostty"
      "google-chrome"
      "home-assistant"
      "readdle-spark"
      "setapp"
      "slack"
    ];
  };

  # macOS-specific system packages
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
  ];

  # nix-darwin state version
  system.stateVersion = 6;
}
