#!/usr/bin/env bash

# Automatic bootstrap script for new Proxmox VMs/LXCs pulling from self-hosted Gitea
set -euo pipefail

# Default Gitea URL (override by passing GITEA_URL environment variable or argument)
GITEA_URL="${1:-${GITEA_URL:-http://gitea.smoochii.dev/smoochii/dotfiles.git}}"

# Target directory (use /etc/nixos/dotfiles if NixOS/root, else ~/.config/dotfiles)
if [ -w "/etc/nixos" ] || [ "${EUID:-$(id -u)}" -eq 0 ]; then
    TARGET_DIR="/etc/nixos/dotfiles"
else
    TARGET_DIR="$HOME/.config/dotfiles"
fi

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==> Starting automatic Proxmox VM bootstrapping...${NC}"
echo -e "${BLUE}==> Repository URL: ${GITEA_URL}${NC}"

# 1. Ensure Nix is installed
if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}==> Nix is not installed. Installing Nix via Determinate Systems Nix Installer...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo -e "${GREEN}==> Nix installed successfully.${NC}"
    echo -e "${YELLOW}IMPORTANT: Please log out and back in (or run 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'), then run this script again.${NC}"
    exit 0
fi

# 2. Ensure Git is available
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}==> Git not found. Running temporarily via nix-shell...${NC}"
    nix-shell -p git --run "bash <(curl -sSL http://gitea.smoochii.dev/smoochii/dotfiles/raw/branch/main/scripts/proxmox-bootstrap.sh) $GITEA_URL"
    exit 0
fi

# 3. Clone or update repository
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

# 4. Detect environment: NixOS vs Non-NixOS Linux
NIXOS_REBUILD_CMD=""

if command -v nixos-rebuild &> /dev/null; then
    NIXOS_REBUILD_CMD="nixos-rebuild"
elif [ -f /run/current-system/sw/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/run/current-system/sw/bin/nixos-rebuild"
elif [ -f /nix/var/nix/profiles/default/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/nix/var/nix/profiles/default/bin/nixos-rebuild"
elif [ -f /etc/NIXOS ] || [ -d /etc/nixos ]; then
    NIXOS_REBUILD_CMD="nix-shell -p nixos-rebuild --run nixos-rebuild"
fi

if [ -n "$NIXOS_REBUILD_CMD" ]; then
    echo -e "${BLUE}==> NixOS detected! Rebuilding system using .#proxmox-vm profile...${NC}"
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        $NIXOS_REBUILD_CMD switch --flake .#proxmox-vm
    else
        sudo $NIXOS_REBUILD_CMD switch --flake .#proxmox-vm
    fi
    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${GREEN}  Proxmox NixOS VM Bootstrapping Completed Successfully!           ${NC}"
    echo -e "${GREEN}  User 'smoochii' created with SSH key & passwordless sudo.        ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
else
    echo -e "${YELLOW}==> Standard Linux detected (non-NixOS). Applying Home Manager profile...${NC}"
    nix run --extra-experimental-features "nix-command flakes" github:nix-community/home-manager -- switch --flake ".#smoochii@smoochii-linux"
    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${GREEN}  Proxmox Home Manager Bootstrapping Completed Successfully!       ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
fi
