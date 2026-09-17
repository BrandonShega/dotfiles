#!/usr/bin/env bash

# Automatic bootstrap script for new Proxmox NixOS VMs/LXCs pulling from self-hosted Gitea
set -euo pipefail

# Default Gitea URL (override by passing GITEA_URL environment variable or argument)
GITEA_URL="${1:-${GITEA_URL:-http://gitea.smoochii.dev/smoochii/dotfiles.git}}"
TARGET_DIR="/etc/nixos/dotfiles"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}==> Starting automatic Proxmox NixOS VM bootstrapping...${NC}"
echo -e "${BLUE}==> Repository URL: ${GITEA_URL}${NC}"

# 1. Ensure Git is available
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}==> Git not found. Installing git temporarily via nix-shell...${NC}"
    nix-shell -p git --run "$0 $GITEA_URL"
    exit 0
fi

# 2. Clone or update repository
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${BLUE}==> Cloning dotfiles repo into $TARGET_DIR...${NC}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    git clone "$GITEA_URL" "$TARGET_DIR"
else
    echo -e "${BLUE}==> Updating existing dotfiles repo in $TARGET_DIR...${NC}"
    cd "$TARGET_DIR"
    git pull || true
fi

cd "$TARGET_DIR"

# 3. Apply NixOS proxmox-vm Flake profile
echo -e "${BLUE}==> Rebuilding system using .#proxmox-vm profile...${NC}"
sudo nixos-rebuild switch --flake .#proxmox-vm

echo -e "${GREEN}===================================================================${NC}"
echo -e "${GREEN}  Proxmox NixOS VM Bootstrapping Completed Successfully!           ${NC}"
echo -e "${GREEN}  User 'smoochii' created with SSH key & passwordless sudo.        ${NC}"
echo -e "${GREEN}===================================================================${NC}"
