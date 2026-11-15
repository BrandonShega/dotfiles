{ config, pkgs, lib, ... }:

{
  # Enable Grafana Alloy log collector daemon
  services.alloy = {
    enable = true;
    configPath = ../../config/alloy/config.alloy;
  };

  # Run Alloy as root so it can read both systemd-journal and /var/run/docker.sock
  # (without failing on hosts where the 'docker' group does not exist)
  systemd.services.alloy.serviceConfig = {
    User = "root";
    Group = "root";
    DynamicUser = lib.mkForce false;
  };
}

