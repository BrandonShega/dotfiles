#!/usr/bin/env bash

# Universal Proxmox VM/LXC Bootstrapper
# Works on NixOS, Ubuntu, Debian, Kali, Alpine, Arch, Proxmox VE, etc.
set -euo pipefail

GITEA_URL="${1:-${GITEA_URL:-https://gitea.smoochii.dev/smoochii/dotfiles.git}}"
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

# Install Alpine Linux prerequisites if running on Alpine
if [ "$IS_ROOT" = true ] && (command -v apk &>/dev/null || [ -f /etc/alpine-release ]); then
    echo -e "${BLUE}==> Installing Alpine Linux prerequisites (xz, bash, curl, git, shadow, sudo, ca-certificates)...${NC}"
    apk update 2>/dev/null || true
    apk add xz bash curl git shadow sudo ca-certificates || true
fi

GITEA_DOMAIN="gitea.smoochii.dev"
GITEA_IP="${GITEA_IP:-10.10.1.102}"

# Fallback DNS resolution if machine cannot resolve gitea.smoochii.dev
if [ "$IS_ROOT" = true ] && [ -n "$GITEA_IP" ]; then
    if ! getent hosts "$GITEA_DOMAIN" &>/dev/null && ! ping -c 1 -w 2 "$GITEA_DOMAIN" &>/dev/null; then
        echo -e "${YELLOW}==> Adding fallback DNS mapping for ${GITEA_DOMAIN} (${GITEA_IP}) to /etc/hosts...${NC}"
        echo "${GITEA_IP} ${GITEA_DOMAIN}" >> /etc/hosts
    fi
fi

# 1. Non-NixOS System Setup (User creation, SSH key injection, Sudo, SSH config)
if [ ! -f /etc/NIXOS ] && [ "$IS_ROOT" = true ]; then
    echo -e "${BLUE}==> Setting up user '${TARGET_USER}' on ${OS_ID}...${NC}"

    # Create user if missing with guaranteed host shell (/bin/bash or /bin/sh)
    if ! id "$TARGET_USER" &>/dev/null; then
        echo -e "${BLUE}==> Creating user '${TARGET_USER}'...${NC}"
        SHELL_PATH="$(which bash 2>/dev/null || which sh 2>/dev/null || echo "/bin/sh")"
        useradd -m -s "$SHELL_PATH" "$TARGET_USER" || adduser -D -s "$SHELL_PATH" "$TARGET_USER" || true
    fi

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

    # Generate UTF-8 locale on Debian/PVE/Ubuntu to fix Zsh character duplication
    if [ -f /etc/locale.gen ]; then
        sed -i 's/^#\? \?en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
        locale-gen 2>/dev/null || true
    fi
fi

# 2. Ensure Nix is installed
export PATH="/nix/var/nix/profiles/default/bin:$PATH"

if ! command -v nix &> /dev/null && [ ! -x /nix/var/nix/profiles/default/bin/nix ] && [ ! -x "$HOME/.nix-profile/bin/nix" ]; then
    echo -e "${YELLOW}==> Nix is not installed. Installing Nix...${NC}"
    if ! command -v systemctl &>/dev/null && [ ! -d /run/systemd/system ]; then
        echo -e "${YELLOW}==> Non-systemd init detected (Alpine/OpenRC). Setting up /nix ownership for '${TARGET_USER}'...${NC}"
        mkdir -p /nix
        chown -R "${TARGET_USER}:" /nix 2>/dev/null || true
        if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
            su -s /bin/sh "$TARGET_USER" -c "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"
        else
            curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
        fi
    else
        echo -e "${YELLOW}==> Installing Nix via Determinate Systems Nix Installer (Unattended)...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi
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

# Configure git safe.directory to bypass dubious ownership warnings
if command -v git &> /dev/null; then
    git config --global --add safe.directory "$TARGET_DIR" 2>/dev/null || true
    git config --global --add safe.directory "*" 2>/dev/null || true
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${BLUE}==> Cloning dotfiles repo into $TARGET_DIR...${NC}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    if command -v git &> /dev/null; then
        git -c safe.directory="*" clone "$GITEA_URL" "$TARGET_DIR"
    else
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" clone "$GITEA_URL" "$TARGET_DIR"
    fi
else
    echo -e "${BLUE}==> Updating existing dotfiles repo in $TARGET_DIR...${NC}"
    cd "$TARGET_DIR"
    if command -v git &> /dev/null; then
        git -c safe.directory="*" pull || true
    else
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" pull || true
    fi
fi

if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
    chown -R "${TARGET_USER}:" "/home/${TARGET_USER}" 2>/dev/null || true
    chmod 755 "/home/${TARGET_USER}" 2>/dev/null || true
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
    FLAKE_TARGET="${FLAKE_TARGET:-.#smoochii@server-lxc}"
    if [ "$OS_ID" = "kali" ]; then
        FLAKE_TARGET=".#kali@kali-linux"
    fi

    echo -e "${YELLOW}==> Standard Linux (${OS_ID}) detected. Applying Home Manager profile (${FLAKE_TARGET})...${NC}"

    if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
        echo -e "${BLUE}==> Activating Home Manager as user '${TARGET_USER}'...${NC}"
        EXEC_SHELL="$(which bash 2>/dev/null || which sh 2>/dev/null || echo "/bin/sh")"
        if command -v runuser &>/dev/null; then
            runuser -u "$TARGET_USER" -- "$EXEC_SHELL" -c "
                set -e
                [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                [ -f \$HOME/.nix-profile/etc/profile.d/nix.sh ] && . \$HOME/.nix-profile/etc/profile.d/nix.sh
                [ -L \$HOME/.config/nvim ] && rm -rf \$HOME/.config/nvim
                if command -v git &>/dev/null; then
                    git config --global --add safe.directory '${TARGET_DIR}' 2>/dev/null || true
                    git config --global --add safe.directory '*' 2>/dev/null || true
                fi
                cd '${TARGET_DIR}'
                for f in \"\$HOME/.zshrc\" \"\$HOME/.bashrc\" \"\$HOME/.bash_profile\" \"\$HOME/.profile\" \"\$HOME/.zshenv\" \"\$HOME/.config/starship.toml\" \"\$HOME/.ssh/config\"; do
                    if [ -f \"\$f\" ] && [ ! -L \"\$f\" ]; then
                        mv \"\$f\" \"\${f}.backup\" 2>/dev/null || true
                    fi
                done
                CLEAN_TARGET=\"\$(echo '${FLAKE_TARGET}' | sed 's/^\.#//')\"
                nix build --extra-experimental-features 'nix-command flakes' \".#homeConfigurations.\\\"\$CLEAN_TARGET\\\".activationPackage\" --out-link \"\$HOME/.hm-result\"
                \"\$HOME/.hm-result/activate\"
                rm -f \"\$HOME/.hm-result\"
            "
        else
            su -s "$EXEC_SHELL" "$TARGET_USER" -c "
                set -e
                [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                [ -f \$HOME/.nix-profile/etc/profile.d/nix.sh ] && . \$HOME/.nix-profile/etc/profile.d/nix.sh
                [ -L \$HOME/.config/nvim ] && rm -rf \$HOME/.config/nvim
                if command -v git &>/dev/null; then
                    git config --global --add safe.directory '${TARGET_DIR}' 2>/dev/null || true
                    git config --global --add safe.directory '*' 2>/dev/null || true
                fi
                cd '${TARGET_DIR}'
                for f in \"\$HOME/.zshrc\" \"\$HOME/.bashrc\" \"\$HOME/.bash_profile\" \"\$HOME/.profile\" \"\$HOME/.zshenv\" \"\$HOME/.config/starship.toml\" \"\$HOME/.ssh/config\"; do
                    if [ -f \"\$f\" ] && [ ! -L \"\$f\" ]; then
                        mv \"\$f\" \"\${f}.backup\" 2>/dev/null || true
                    fi
                done
                CLEAN_TARGET=\"\$(echo '${FLAKE_TARGET}' | sed 's/^\.#//')\"
                nix build --extra-experimental-features 'nix-command flakes' \".#homeConfigurations.\\\"\$CLEAN_TARGET\\\".activationPackage\" --out-link \"\$HOME/.hm-result\"
                \"\$HOME/.hm-result/activate\"
                rm -f \"\$HOME/.hm-result\"
            "
        fi

        # Update login shell to Nix zsh once Home Manager has installed zsh
        USER_HOME="/home/${TARGET_USER}"
        NIX_ZSH="${USER_HOME}/.nix-profile/bin/zsh"
        if [ -x "$NIX_ZSH" ]; then
            if [ -f /etc/shells ] && ! grep -qF "$NIX_ZSH" /etc/shells; then
                echo "$NIX_ZSH" >> /etc/shells
            fi
            chsh -s "$NIX_ZSH" "$TARGET_USER" 2>/dev/null || usermod -s "$NIX_ZSH" "$TARGET_USER" 2>/dev/null || true
        fi
    else
        [ -L "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
        for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.config/starship.toml" "$HOME/.ssh/config"; do
            if [ -f "$f" ] && [ ! -L "$f" ]; then
                mv "$f" "${f}.backup" 2>/dev/null || true
            fi
        done
        cd "$TARGET_DIR"
        CLEAN_TARGET="$(echo "$FLAKE_TARGET" | sed 's/^\.#//')"
        nix build --extra-experimental-features "nix-command flakes" ".#homeConfigurations.\"$CLEAN_TARGET\".activationPackage" --out-link "$HOME/.hm-result"
        "$HOME/.hm-result/activate"
        rm -f "$HOME/.hm-result"
    fi

    # Clean up old Nix store generations to reclaim disk space automatically
    echo -e "${BLUE}==> Purging unneeded Nix packages to reclaim disk space...${NC}"
    if command -v nix-collect-garbage &>/dev/null; then
        nix-collect-garbage -d 2>/dev/null || true
    elif [ -x /nix/var/nix/profiles/default/bin/nix-collect-garbage ]; then
        /nix/var/nix/profiles/default/bin/nix-collect-garbage -d 2>/dev/null || true
    fi

    echo -e "${GREEN}===================================================================${NC}"
    echo -e "${GREEN}  Proxmox (${OS_ID}) Bootstrapping Completed Successfully!           ${NC}"
    echo -e "${GREEN}  User '${TARGET_USER}' created with SSH key & passwordless sudo. ${NC}"
    echo -e "${GREEN}===================================================================${NC}"
fi
