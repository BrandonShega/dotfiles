{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        user = "smoochii";
        identityFile = "~/.ssh/smoochii";
        identitiesOnly = true;
        extraOptions = {
          CanonicalizeHostname = "yes";
          CanonicalDomains = "smoochii.dev";
          CanonicalizeMaxDots = "1";
        };
      };
      "github.com" = {
        user = "git";
        identityFile = "~/.ssh/smoochii";
      };
    };
  };
}
