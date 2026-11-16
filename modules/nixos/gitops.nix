{ config, pkgs, ... }:

{
  # Declarative GitOps auto-upgrade for NixOS VMs
  system.autoUpgrade = {
    enable = true;
    flake = "github:BrandonShega/dotfiles#proxmox-vm";
    dates = "*:0/15"; # Poll every 15 minutes
    randomizedDelaySec = "60sec";
    allowReboot = false;
  };
}
