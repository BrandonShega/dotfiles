#!/usr/bin/env bash

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==> Starting Nix bootstrapping script...${NC}"

# 1. Install Nix if missing
if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}==> Nix is not installed. Installing via Determinate Systems Nix Installer...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    
    echo -e "${GREEN}==> Nix installation completed successfully.${NC}"
    echo -e "${YELLOW}IMPORTANT: Please open a new terminal window / session and run this script again to apply your configuration.${NC}"
    exit 0
fi

echo -e "${GREEN}==> Nix is installed: $(nix --version)${NC}"

# 2. Decrypt SSH Key if secret exists and ~/.ssh/smoochii is missing
if [ -f "secrets/smoochii.age" ] && [ ! -f "$HOME/.ssh/smoochii" ]; then
    echo -e "${BLUE}==> Restoring encrypted SSH key from secrets/smoochii.age...${NC}"
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    
    echo -e "${YELLOW}===================================================================${NC}"
    echo -e "${YELLOW}PROMPT: Enter your AGE PASSPHRASE for the SSH key${NC}"
    echo -e "${YELLOW}===================================================================${NC}"

    # Decrypt private key
    if command -v age &> /dev/null; then
        age -d -o "$HOME/.ssh/smoochii" secrets/smoochii.age
    else
        nix run nixpkgs#age -- -d -o "$HOME/.ssh/smoochii" secrets/smoochii.age
    fi
    chmod 600 "$HOME/.ssh/smoochii"
    
    # Automatically derive matching public key
    ssh-keygen -y -f "$HOME/.ssh/smoochii" > "$HOME/.ssh/smoochii.pub"
    chmod 644 "$HOME/.ssh/smoochii.pub"
    echo -e "${GREEN}==> SSH private and public keys successfully restored to ~/.ssh/smoochii${NC}"
fi

# 3. Interactive Profile Selection or Argument Parsing
PROFILE="${1:-}"

if [ -z "$PROFILE" ]; then
    echo -e "\n${BLUE}Select the host profile to bootstrap:${NC}"
    echo "1) Personal Mac (nix-darwin + home-manager: .#smoochii-mac)"
    echo "2) Personal Linux (home-manager standalone: .#smoochii@smoochii-linux)"
    echo "3) Cybersecurity VM (home-manager standalone: .#kali@kali-linux)"
    echo "4) Proxmox VM / LXC (NixOS + home-manager: .#proxmox-vm)"
    read -rp "Enter choice [1-4]: " CHOICE
    case "$CHOICE" in
        1) PROFILE="mac" ;;
        2) PROFILE="linux" ;;
        3) PROFILE="kali" ;;
        4) PROFILE="proxmox" ;;
        *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
    esac
fi

# 4. Execute Selected Profile Setup
case "$PROFILE" in
    mac|smoochii-mac)
        echo -e "${BLUE}==> Bootstrapping Personal Mac profile (.#smoochii-mac)...${NC}"
        if ! command -v darwin-rebuild &> /dev/null; then
            sudo -H nix run --extra-experimental-features "nix-command flakes" github:LnL7/nix-darwin/master -- switch --flake .#smoochii-mac
        else
            sudo -H darwin-rebuild switch --flake .#smoochii-mac
        fi
        ;;
    linux|smoochii-linux)
        echo -e "${BLUE}==> Bootstrapping Personal Linux profile (.#smoochii@smoochii-linux)...${NC}"
        nix run --extra-experimental-features "nix-command flakes" github:nix-community/home-manager -- switch --flake ".#smoochii@smoochii-linux"
        ;;
    kali|kali-linux|cyber-vm)
        echo -e "${BLUE}==> Bootstrapping Cybersecurity VM profile (.#kali@kali-linux)...${NC}"
        nix run --extra-experimental-features "nix-command flakes" github:nix-community/home-manager -- switch --flake ".#kali@kali-linux"
        ;;
    proxmox|proxmox-vm)
        echo -e "${BLUE}==> Bootstrapping Proxmox NixOS VM profile (.#proxmox-vm)...${NC}"
        sudo -H nixos-rebuild switch --flake .#proxmox-vm
        ;;
    *)
        echo -e "${RED}Unknown profile: $PROFILE${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}==> Profile '$PROFILE' bootstrapped successfully!${NC}"
