{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "work" ];
    settings = {
      "*" = {
        identityFile = [
          "~/.ssh/smoochii"
          "~/.ssh/id_ed25519"
          "~/.ssh/id_rsa"
        ];
      };
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
