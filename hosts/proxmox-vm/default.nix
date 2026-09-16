{ pkgs, ... }:

{
  # Enable OpenSSH daemon with password authentication disabled
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Create user 'smoochii' with authorized SSH key
  users.users.smoochii = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJIcVSDFWPdC0+bD4Rr6C2wKn8bbBCBV6IJ8x4SWI/WR smoochii@Brandons-MacBook-Air.local"
    ];
  };

  # Enable passwordless sudo for convenience in homelab VMs
  security.sudo.wheelNeedsPassword = false;

  # Base system packages
  environment.systemPackages = with pkgs; [
    curl
    git
    vim
    wget
    htop
  ];

  # Enable Zsh system-wide
  programs.zsh.enable = true;

  # NixOS state version
  system.stateVersion = "24.05";
}
