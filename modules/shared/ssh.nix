{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        User smoochii
        IdentityFile ~/.ssh/smoochii
        CanonicalizeHostname yes
        CanonicalDomains smoochii.dev
        CanonicalizeMaxDots 1
        IdentitiesOnly yes

      Host github.com
        User git
        IdentityFile ~/.ssh/smoochii
    '';
  };
}
