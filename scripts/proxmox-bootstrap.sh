#!/usr/bin/env bash

# Universal Proxmox VM/LXC Bootstrapper
# Works on NixOS, Ubuntu, Debian, Kali, Alpine, Arch, etc.
set -euo pipefail

GITEA_URL="${1:-${GITEA_URL:-http://gitea.smoochii.dev/smoochii/dotfiles.git}}"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJIcVSDFWPdC0+bD4Rr6C2wKn8bbBCBV6IJ8x4SWI/WR smoochii@Brandons-MacBook-Air.local"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==> Starting universal Proxmox VM/LXC bootstrapping...${NC}"
echo -e "${BLUE}==> Repository URL: ${GITEA_URL}${NC}"

IS_ROOT=false
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    IS_ROOT=true
fi

# Detect OS distribution
OS_ID="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
fi

TARGET_USER="smoochii"
if [ "$OS_ID" = "kali" ]; then
    TARGET_USER="kali"
fi

# 1. Non-NixOS System Setup (User creation, SSH key injection, Sudo, SSH config)
if [ ! -f /etc/NIXOS ] && [ "$IS_ROOT" = true ]; then
    echo -e "${BLUE}==> Setting up user '${TARGET_USER}' on ${OS_ID}...${NC}"

    # Create user if missing
    if ! id "$TARGET_USER" &>/dev/null; then
        echo -e "${BLUE}==> Creating user '${TARGET_USER}'...${NC}"
        ZSH_PATH="$(which zsh 2>/dev/null || echo "/bin/zsh")"
        useradd -m -s "$ZSH_PATH" "$TARGET_USER" || adduser -D -s "$ZSH_PATH" "$TARGET_USER" || true
    fi

    # Set user shell to Zsh
    ZSH_PATH="$(which zsh 2>/dev/null || echo "/bin/zsh")"
    chsh -s "$ZSH_PATH" "$TARGET_USER" 2>/dev/null || usermod -s "$ZSH_PATH" "$TARGET_USER" 2>/dev/null || true

    # Grant passwordless sudo / wheel
    SUDO_GROUP="sudo"
    if grep -q "^wheel:" /etc/group; then
        SUDO_GROUP="wheel"
    fi
    usermod -aG "$SUDO_GROUP" "$TARGET_USER" 2>/dev/null || addgroup "$TARGET_USER" "$SUDO_GROUP" 2>/dev/null || true

    mkdir -p /etc/sudoers.d
    echo "${TARGET_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-${TARGET_USER}"
    chmod 0440 "/etc/sudoers.d/99-${TARGET_USER}"

    # Setup SSH key for user
    USER_HOME="/home/${TARGET_USER}"
    if [ "$TARGET_USER" = "root" ]; then
        USER_HOME="/root"
    fi
    chmod 755 "${USER_HOME}" 2>/dev/null || true
    chown "${TARGET_USER}:" "${USER_HOME}" 2>/dev/null || true
    mkdir -p "${USER_HOME}/.ssh"
    chmod 700 "${USER_HOME}/.ssh"
    
    # Ensure authorized_keys exists and ends with a newline
    touch "${USER_HOME}/.ssh/authorized_keys"
    if [ -s "${USER_HOME}/.ssh/authorized_keys" ] && [ -n "$(tail -c1 "${USER_HOME}/.ssh/authorized_keys")" ]; then
        echo "" >> "${USER_HOME}/.ssh/authorized_keys"
    fi

    if ! grep -qF "$SSH_KEY" "${USER_HOME}/.ssh/authorized_keys" 2>/dev/null; then
        echo "$SSH_KEY" >> "${USER_HOME}/.ssh/authorized_keys"
    fi
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    chown -R "${TARGET_USER}:" "${USER_HOME}/.ssh" 2>/dev/null || true

    # Disable SSH password authentication system-wide & enforce key auth
    if [ -f /etc/ssh/sshd_config ]; then
        if [ -d /etc/ssh/sshd_config.d ]; then
            echo -e "PasswordAuthentication no\nKbdInteractiveAuthentication no\nPubkeyAuthentication yes" > /etc/ssh/sshd_config.d/99-disable-passwords.conf
        fi

        # Also apply directly to main sshd_config for max compatibility
        sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true

        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || rc-service sshd restart 2>/dev/null || true
        echo -e "${GREEN}==> SSH configured: Password authentication disabled, SSH key authentication enforced.${NC}"
    fi
fi

# 2. Ensure Nix is installed
if ! command -v nix &> /dev/null; then
    echo -e "${YELLOW}==> Nix is not installed. Installing Nix via Determinate Systems Nix Installer...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    echo -e "${GREEN}==> Nix installed successfully.${NC}"
fi

# Immediately source Nix environment into current execution
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
export PATH="/nix/var/nix/profiles/default/bin:$PATH"

# 3. Clone or update repository
if [ -f "/etc/NIXOS" ]; then
    TARGET_DIR="/etc/nixos/dotfiles"
elif [ "$IS_ROOT" = true ]; then
    TARGET_DIR="/home/${TARGET_USER}/.config/dotfiles"
else
    TARGET_DIR="$HOME/.config/dotfiles"
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${BLUE}==> Cloning dotfiles repo into $TARGET_DIR...${NC}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    if command -v git &> /dev/null; then
        git clone "$GITEA_URL" "$TARGET_DIR"
    else
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone "$GITEA_URL" "$TARGET_DIR"
    fi
else
    echo -e "${BLUE}==> Updating existing dotfiles repo in $TARGET_DIR...${NC}"
    cd "$TARGET_DIR"
    if command -v git &> /dev/null; then
        git pull || true
    else
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- pull || true
    fi
fi

if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
    chown -R "${TARGET_USER}:" "$TARGET_DIR" 2>/dev/null || true
fi

# 4. Apply target profile based on OS
NIXOS_REBUILD_CMD=""
if command -v nixos-rebuild &> /dev/null; then
    NIXOS_REBUILD_CMD="nixos-rebuild"
elif [ -f /run/current-system/sw/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/run/current-system/sw/bin/nixos-rebuild"
elif [ -f /nix/var/nix/profiles/default/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/nix/var/nix/profiles/default/bin/nixos-rebuild"
fi

if [ -f /etc/NIXOS ]; then
    echo -e "${BLUE}==> NixOS detected! Rebuilding system using .#proxmox-vm profile...${NC}"
    ${NIXOS_REBUILD_CMD:-nixos-rebuild} switch --flake .#proxmox-vm
    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${GREEN}  Proxmox NixOS VM Bootstrapping Completed Successfully!           ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
else
    FLAKE_TARGET=".#smoochii@smoochii-linux"
    if [ "$OS_ID" = "kali" ]; then
        FLAKE_TARGET=".#kali@kali-linux"
    fi

    echo -e "${YELLOW}==> Standard Linux (${OS_ID}) detected. Applying Home Manager profile (${FLAKE_TARGET})...${NC}"

    if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
        echo -e "${BLUE}==> Activating Home Manager as user '${TARGET_USER}'...${NC}"
        su - "$TARGET_USER" -c "
            [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
            [ -f \$HOME/.nix-profile/etc/profile.d/nix.sh ] && . \$HOME/.nix-profile/etc/profile.d/nix.sh
            [ -L \$HOME/.config/nvim ] && rm -rf \$HOME/.config/nvim
            cd '${TARGET_DIR}'
            nix run --extra-experimental-features 'nix-command flakes' github:nix-community/home-manager -- switch -b backup --flake '${FLAKE_TARGET}'
        "
    else
        [ -L "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
        nix run --extra-experimental-features "nix-command flakes" github:nix-community/home-manager -- switch -b backup --flake "$FLAKE_TARGET"
    fi

    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${GREEN}  Proxmox (${OS_ID}) Bootstrapping Completed Successfully!           ${NC}"
    echo -e "${GREEN}  User '${TARGET_USER}' created with SSH key & passwordless sudo. ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
fi
