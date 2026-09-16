{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "work" ];
    settings = {
      "*.smoochii.dev smoochii.dev" = {
        user = "smoochii";
        identityFile = "~/.ssh/smoochii";
        CanonicalizeHostname = "yes";
        CanonicalDomains = "smoochii.dev";
        IdentitiesOnly = "yes";
      };
    };
  };
}
