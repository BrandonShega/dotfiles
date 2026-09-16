{
  description = "Multi-host Nix Flake dotfiles (nix-darwin + Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: {
    # Personal Mac Configuration (nix-darwin + home-manager)
    darwinConfigurations.smoochii-mac = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin"; # Apple Silicon Mac
      modules = [
        ./hosts/personal-mac/default.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.smoochii = import ./hosts/personal-mac/home.nix;
        }
      ];
    };

    # Standalone Home Manager Configurations for Linux
    homeConfigurations = {
      "smoochii@smoochii-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./hosts/personal-linux/home.nix
        ];
      };

      "kali@kali-linux" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./hosts/cyber-vm/home.nix
        ];
      };
    };
  };
}
