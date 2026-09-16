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

echo -e "${GREEN}==> Nix is already installed: $(nix --version)${NC}"

# 2. Check if running on macOS or Linux
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${YELLOW}==> Linux target detected. Standalone Home Manager configurations can be built with:${NC}"
    echo -e "    nix run github:nix-community/home-manager -- switch --flake .#smoochii@smoochii-linux"
    echo -e "    nix run github:nix-community/home-manager -- switch --flake .#kali@kali-linux"
    exit 0
fi

# 3. Bootstrap nix-darwin
if ! command -v darwin-rebuild &> /dev/null; then
    echo -e "${YELLOW}==> darwin-rebuild not found in PATH. Bootstrapping nix-darwin...${NC}"
    # Use extra experimental features flag to guarantee it works on freshly installed Nix
    nix run --extra-experimental-features "nix-command flakes" github:LnL7/nix-darwin/master -- switch --flake .#smoochii-mac
else
    echo -e "${BLUE}==> Applying nix-darwin configuration...${NC}"
    darwin-rebuild switch --flake .#smoochii-mac
fi

echo -e "${GREEN}==> nix-darwin configuration applied successfully!${NC}"
