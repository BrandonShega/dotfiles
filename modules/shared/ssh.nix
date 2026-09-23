{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        User = "smoochii";
        IdentityFile = "~/.ssh/smoochii";
        IdentitiesOnly = "yes";
        CanonicalizeHostname = "yes";
        CanonicalDomains = "smoochii.dev";
        CanonicalizeMaxDots = "2";
      };
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/smoochii";
      };
    };
  };
}
