{ config, pkgs, lib, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.grafana-alloy
  ];

  # Deploy Alloy configuration to ~/.config/alloy/config.alloy on Linux hosts
  xdg.configFile."alloy/config.alloy" = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    source = ../../config/alloy/config.alloy;
    force = true;
  };
}

