#!/usr/bin/env bash

# Universal Proxmox VM/LXC Bootstrapper
# Works on NixOS, Ubuntu, Debian, Kali, Alpine, Arch, Proxmox VE, etc.
set -e
(set -o pipefail 2>/dev/null) && set -o pipefail || true

# Guarantee HOME and USER are set (qm guest exec, pct exec, and cron often omit them)
if [ "$(id -u)" -eq 0 ]; then
    export HOME="${HOME:-/root}"
    export USER="${USER:-root}"
else
    export USER="${USER:-$(id -un 2>/dev/null || echo smoochii)}"
    export HOME="${HOME:-/home/$USER}"
fi

GITEA_URL="${1:-${GITEA_URL:-https://gitea.smoochii.dev/smoochii/dotfiles.git}}"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJIcVSDFWPdC0+bD4Rr6C2wKn8bbBCBV6IJ8x4SWI/WR smoochii@Brandons-MacBook-Air.local"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    printf "%b\n" "$1"
}

log "${BLUE}==> Starting universal Proxmox VM/LXC bootstrapping...${NC}"
log "${BLUE}==> Repository URL: ${GITEA_URL}${NC}"

IS_ROOT=false
if [ "$(id -u)" -eq 0 ]; then
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

# 0. Free cached space & auto-expand root filesystem if disk was enlarged in Proxmox UI
if [ "$IS_ROOT" = true ]; then
    apt-get clean 2>/dev/null || true
    rm -rf /var/cache/apt/archives/*.deb /var/lib/apt/lists/* 2>/dev/null || true
    journalctl --vacuum-size=50M 2>/dev/null || true

    # If a previous partial Nix install failed due to disk full, clean incomplete /nix store
    if [ -d /nix ] && ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
        log "${YELLOW}==> Cleaning up incomplete previous /nix installation...${NC}"
        systemctl stop nix-daemon.socket nix-daemon.service 2>/dev/null || true
        rm -rf /nix/* /etc/nix 2>/dev/null || true
    fi

    ROOT_DEV="$(df -P / 2>/dev/null | awk 'NR==2 {print $1}')"
    if [ -n "$ROOT_DEV" ] && [ -b "$ROOT_DEV" ]; then
        if command -v lvs >/dev/null 2>&1 && lvs "$ROOT_DEV" >/dev/null 2>&1; then
            VG_NAME="$(lvs --noheadings -o vg_name "$ROOT_DEV" 2>/dev/null | tr -d ' ')"
            for PV_DEV in $(pvs --noheadings -o pv_name -S vg_name="$VG_NAME" 2>/dev/null | tr -d ' '); do
                DISK_DEV="$(lsblk -ndo pkname "$PV_DEV" 2>/dev/null | head -n1)"
                PART_NUM="$(echo "$PV_DEV" | grep -o '[0-9]*$')"
                if [ -n "$DISK_DEV" ] && [ -n "$PART_NUM" ]; then
                    if [ "$PART_NUM" -ge 5 ]; then
                        EXT_PART="$(sfdisk -d "/dev/$DISK_DEV" 2>/dev/null | awk '/Id= ?5|Id=85|type=5|Extended/ {print $1}' | grep -o '[0-9]*$' | head -n1)"
                        if [ -n "$EXT_PART" ]; then
                            echo ", +" | sfdisk -N "$EXT_PART" --force "/dev/$DISK_DEV" 2>/dev/null || parted -s "/dev/$DISK_DEV" resizepart "$EXT_PART" 100% 2>/dev/null || true
                        fi
                    fi
                    growpart "/dev/$DISK_DEV" "$PART_NUM" 2>/dev/null || echo ", +" | sfdisk -N "$PART_NUM" --force "/dev/$DISK_DEV" 2>/dev/null || parted -s "/dev/$DISK_DEV" resizepart "$PART_NUM" 100% 2>/dev/null || true
                    partx -u "/dev/$DISK_DEV" 2>/dev/null || partprobe "/dev/$DISK_DEV" 2>/dev/null || true
                fi
                pvresize "$PV_DEV" 2>/dev/null || true
            done
            lvextend -l +100%FREE "$ROOT_DEV" 2>/dev/null || true
            resize2fs "$ROOT_DEV" 2>/dev/null || xfs_growfs / 2>/dev/null || true
        else
            DISK_DEV="$(lsblk -ndo pkname "$ROOT_DEV" 2>/dev/null | head -n1)"
            PART_NUM="$(echo "$ROOT_DEV" | grep -o '[0-9]*$')"
            if [ -n "$DISK_DEV" ] && [ -n "$PART_NUM" ]; then
                growpart "/dev/$DISK_DEV" "$PART_NUM" 2>/dev/null || echo ", +" | sfdisk -N "$PART_NUM" --force "/dev/$DISK_DEV" 2>/dev/null || parted -s "/dev/$DISK_DEV" resizepart "$PART_NUM" 100% 2>/dev/null || true
                partx -u "/dev/$DISK_DEV" 2>/dev/null || partprobe "/dev/$DISK_DEV" 2>/dev/null || true
            fi
            resize2fs "$ROOT_DEV" 2>/dev/null || xfs_growfs / 2>/dev/null || true
        fi
    fi
fi

# Install Alpine Linux prerequisites if running on Alpine
if command -v apk >/dev/null 2>&1 || [ -f /etc/alpine-release ]; then
    log "${BLUE}==> Upgrading musl C library and installing Alpine prerequisites...${NC}"
    apk update 2>/dev/null || true
    apk add --upgrade musl 2>/dev/null || true
    apk add xz bash curl git shadow sudo coreutils ca-certificates ncurses-terminfo-base ncurses-terminfo musl-locales lang 2>/dev/null || true
fi

GITEA_DOMAIN="gitea.smoochii.dev"
# Remove stale 10.10.1.102 mapping added by older bootstrap versions
if [ "$IS_ROOT" = true ] && [ -f /etc/hosts ]; then
    sed -i '/10\.10\.1\.102[[:space:]].*gitea\.smoochii\.dev/d' /etc/hosts 2>/dev/null || true
fi

GITHUB_URL="https://github.com/BrandonShega/dotfiles.git"
ACTIVE_REPO_URL="$GITHUB_URL"
if ! curl -kfsSLI --connect-timeout 2 --max-time 3 "https://github.com" >/dev/null 2>&1; then
    log "${YELLOW}==> GitHub not reachable within 2s; falling back to Gitea (${GITEA_URL})...${NC}"
    ACTIVE_REPO_URL="$GITEA_URL"
fi

# 1. Non-NixOS System Setup (User creation, SSH key injection, Sudo, SSH config)
if [ ! -f /etc/NIXOS ] && [ "$IS_ROOT" = true ]; then
    log "${BLUE}==> Setting up user '${TARGET_USER}' on ${OS_ID}...${NC}"

    # Create user if missing with guaranteed host shell (/bin/bash or /bin/sh)
    if ! id -u "$TARGET_USER" >/dev/null 2>&1 && ! grep -q "^${TARGET_USER}:" /etc/passwd 2>/dev/null; then
        log "${BLUE}==> Creating user '${TARGET_USER}'...${NC}"
        SHELL_PATH="$(command -v bash 2>/dev/null || command -v sh 2>/dev/null || echo "/bin/sh")"
        if command -v useradd >/dev/null 2>&1; then
            useradd -m -s "$SHELL_PATH" "$TARGET_USER" 2>/dev/null || true
        elif [ -f /etc/alpine-release ]; then
            adduser -D -s "$SHELL_PATH" "$TARGET_USER" 2>/dev/null || true
        else
            adduser --disabled-password --gecos "" --shell "$SHELL_PATH" "$TARGET_USER" 2>/dev/null || true
        fi
    fi

    # Grant passwordless sudo / wheel
    SUDO_GROUP="sudo"
    if grep -q "^wheel:" /etc/group 2>/dev/null; then
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
    mkdir -p "${USER_HOME}"
    chmod 755 "${USER_HOME}" 2>/dev/null || true
    chown "${TARGET_USER}" "${USER_HOME}" 2>/dev/null || chown "${TARGET_USER}:" "${USER_HOME}" 2>/dev/null || true
    mkdir -p "${USER_HOME}/.ssh"
    chmod 700 "${USER_HOME}/.ssh"

    # Ensure authorized_keys exists and ends with a newline
    touch "${USER_HOME}/.ssh/authorized_keys"
    if [ -s "${USER_HOME}/.ssh/authorized_keys" ] && [ -n "$(tail -c1 "${USER_HOME}/.ssh/authorized_keys" 2>/dev/null)" ]; then
        echo "" >> "${USER_HOME}/.ssh/authorized_keys"
    fi

    if ! grep -qF "$SSH_KEY" "${USER_HOME}/.ssh/authorized_keys" 2>/dev/null; then
        echo "$SSH_KEY" >> "${USER_HOME}/.ssh/authorized_keys"
    fi
    chmod 600 "${USER_HOME}/.ssh/authorized_keys"
    chown -R "${TARGET_USER}" "${USER_HOME}/.ssh" 2>/dev/null || chown -R "${TARGET_USER}:" "${USER_HOME}/.ssh" 2>/dev/null || true

    # Disable SSH password authentication system-wide & enforce key auth
    if [ -f /etc/ssh/sshd_config ]; then
        if [ -d /etc/ssh/sshd_config.d ]; then
            printf "PasswordAuthentication no\nKbdInteractiveAuthentication no\nPubkeyAuthentication yes\n" > /etc/ssh/sshd_config.d/99-disable-passwords.conf
        fi

        # Also apply directly to main sshd_config for max compatibility
        sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/^#\?KbdInteractiveAuthentication .*/KbdInteractiveAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true

        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || rc-service sshd restart 2>/dev/null || true
        log "${GREEN}==> SSH configured: Password authentication disabled, SSH key authentication enforced.${NC}"
    fi

    # Generate UTF-8 locale on Debian/PVE/Ubuntu to fix Zsh character duplication
    if [ -f /etc/locale.gen ]; then
        sed -i 's/^#\? \?en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen 2>/dev/null || true
        locale-gen 2>/dev/null || true
    fi

    # Install system-wide TERM fallback for modern terminals (Ghostty, Alacritty, Kitty)
    if [ -d /etc/profile.d ]; then
        cat << 'EOF' > /etc/profile.d/99-term-fallback.sh
if [ -n "$TERM" ] && [ "$TERM" != "xterm-256color" ] && [ "$TERM" != "screen-256color" ] && [ "$TERM" != "tmux-256color" ]; then
    if ! command -v infocmp >/dev/null 2>&1 || ! infocmp "$TERM" >/dev/null 2>&1; then
        export TERM=xterm-256color
    fi
fi
EOF
        chmod 644 /etc/profile.d/99-term-fallback.sh
    fi
fi

# 2. Ensure Nix is installed
export PATH="/nix/var/nix/profiles/default/bin:$PATH"

if ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ] && [ ! -x "$HOME/.nix-profile/bin/nix" ]; then
    log "${YELLOW}==> Nix is not installed. Installing Nix...${NC}"
    if ! command -v systemctl >/dev/null 2>&1 && [ ! -d /run/systemd/system ]; then
        log "${YELLOW}==> Non-systemd init detected (Alpine/OpenRC). Setting up /nix ownership for '${TARGET_USER}'...${NC}"
        mkdir -p /nix
        chown -R "${TARGET_USER}" /nix 2>/dev/null || chown -R "${TARGET_USER}:" /nix 2>/dev/null || true
        if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
            su -s /bin/sh "$TARGET_USER" -c "curl -L https://nixos.org/nix/install | sh -s -- --no-daemon"
        else
            curl -L https://nixos.org/nix/install | sh -s -- --no-daemon
        fi
    else
        log "${YELLOW}==> Installing Nix via Determinate Systems Nix Installer (Unattended)...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
    fi
    log "${GREEN}==> Nix installed successfully.${NC}"
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

# Ensure git is installed natively if running as root
if ! command -v git >/dev/null 2>&1 && [ "$IS_ROOT" = true ]; then
    log "${BLUE}==> Installing git...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq 2>/dev/null || true
        apt-get install -y -qq git ca-certificates 2>/dev/null || true
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache git ca-certificates 2>/dev/null || true
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm git ca-certificates 2>/dev/null || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y git ca-certificates 2>/dev/null || true
    fi
fi

# Configure git safe.directory to bypass dubious ownership warnings
if command -v git >/dev/null 2>&1; then
    git config --global --add safe.directory "$TARGET_DIR" 2>/dev/null || true
    git config --global --add safe.directory "*" 2>/dev/null || true
fi

if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
    mkdir -p "$(dirname "$TARGET_DIR")"
    chown -R "${TARGET_USER}" "/home/${TARGET_USER}" 2>/dev/null || chown -R "${TARGET_USER}:" "/home/${TARGET_USER}" 2>/dev/null || true
    chmod 755 "/home/${TARGET_USER}" 2>/dev/null || true
    chmod 755 "$(dirname "$TARGET_DIR")" 2>/dev/null || true
fi

# If running as non-root, ensure user owns their .config directory
if [ "$IS_ROOT" = false ] && [ -d "$HOME/.config" ] && [ ! -w "$HOME/.config" ]; then
    log "${YELLOW}==> Fixing permissions on $HOME/.config...${NC}"
    sudo chown -R "$(id -u):$(id -g)" "$HOME/.config" 2>/dev/null || true
fi

# Clean up broken/incomplete directory from any previous failed clone attempt
if [ -d "$TARGET_DIR" ] && [ ! -d "$TARGET_DIR/.git" ]; then
    log "${YELLOW}==> Removing incomplete repository directory at ${TARGET_DIR}...${NC}"
    rm -rf "$TARGET_DIR"
fi

if [ ! -d "$TARGET_DIR" ]; then
    log "${BLUE}==> Cloning dotfiles repo (${ACTIVE_REPO_URL}) into $TARGET_DIR...${NC}"
    mkdir -p "$(dirname "$TARGET_DIR")"
    if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
        chown -R "${TARGET_USER}" "/home/${TARGET_USER}" 2>/dev/null || chown -R "${TARGET_USER}:" "/home/${TARGET_USER}" 2>/dev/null || true
    fi

    if command -v git >/dev/null 2>&1; then
        if ! git -c safe.directory="*" -c http.connectTimeout=5 clone "$ACTIVE_REPO_URL" "$TARGET_DIR"; then
            log "${YELLOW}==> Primary clone failed. Falling back to Gitea (${GITEA_URL})...${NC}"
            rm -rf "$TARGET_DIR"
            git -c safe.directory="*" -c http.connectTimeout=5 clone "$GITEA_URL" "$TARGET_DIR"
        fi
    else
        if ! nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" -c http.connectTimeout=5 clone "$ACTIVE_REPO_URL" "$TARGET_DIR"; then
            log "${YELLOW}==> Primary clone failed. Falling back to Gitea (${GITEA_URL})...${NC}"
            rm -rf "$TARGET_DIR"
            nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" -c http.connectTimeout=5 clone "$GITEA_URL" "$TARGET_DIR"
        fi
    fi
else
    log "${BLUE}==> Updating existing dotfiles repo in $TARGET_DIR (from ${ACTIVE_REPO_URL})...${NC}"
    cd "$TARGET_DIR"
    if command -v git >/dev/null 2>&1; then
        git -c safe.directory="*" remote set-url origin "$ACTIVE_REPO_URL" 2>/dev/null || true
        git -c safe.directory="*" -c http.connectTimeout=5 fetch origin main 2>/dev/null || {
            git -c safe.directory="*" remote set-url origin "$GITEA_URL" 2>/dev/null || true
            git -c safe.directory="*" -c http.connectTimeout=5 fetch origin main
        }
        git -c safe.directory="*" reset --hard origin/main
    else
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" remote set-url origin "$ACTIVE_REPO_URL" 2>/dev/null || true
        nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- -c safe.directory="*" -c http.connectTimeout=5 pull --ff-only || true
    fi
fi

if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
    chown -R "${TARGET_USER}" "/home/${TARGET_USER}" 2>/dev/null || chown -R "${TARGET_USER}:" "/home/${TARGET_USER}" 2>/dev/null || true
    chmod 755 "/home/${TARGET_USER}" 2>/dev/null || true
fi

# 4. Apply target profile based on OS
NIXOS_REBUILD_CMD=""
if command -v nixos-rebuild >/dev/null 2>&1; then
    NIXOS_REBUILD_CMD="nixos-rebuild"
elif [ -f /run/current-system/sw/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/run/current-system/sw/bin/nixos-rebuild"
elif [ -f /nix/var/nix/profiles/default/bin/nixos-rebuild ]; then
    NIXOS_REBUILD_CMD="/nix/var/nix/profiles/default/bin/nixos-rebuild"
fi

if [ -f /etc/NIXOS ]; then
    log "${BLUE}==> NixOS detected! Rebuilding system using .#proxmox-vm profile...${NC}"
    ${NIXOS_REBUILD_CMD:-nixos-rebuild} switch --flake .#proxmox-vm
    log "${GREEN}===================================================================${NC}"
    log "${GREEN}  Proxmox NixOS VM Bootstrapping Completed Successfully!           ${NC}"
    log "${GREEN}===================================================================${NC}"
else
    FLAKE_TARGET="${FLAKE_TARGET:-.#smoochii@server-lxc}"
    if [ "$OS_ID" = "kali" ]; then
        FLAKE_TARGET=".#kali@kali-linux"
    fi

    log "${YELLOW}==> Standard Linux (${OS_ID}) detected. Applying Home Manager profile (${FLAKE_TARGET})...${NC}"

    # Pre-clean unreferenced Nix store paths before building so small LXCs don't run out of disk space
    if command -v nix-collect-garbage >/dev/null 2>&1; then
        nix-collect-garbage -d >/dev/null 2>&1 || true
    elif [ -x /nix/var/nix/profiles/default/bin/nix-collect-garbage ]; then
        /nix/var/nix/profiles/default/bin/nix-collect-garbage -d >/dev/null 2>&1 || true
    fi

    if [ "$IS_ROOT" = true ] && [ "$TARGET_USER" != "root" ]; then
        log "${BLUE}==> Activating Home Manager as user '${TARGET_USER}'...${NC}"
        EXEC_SHELL="$(command -v bash 2>/dev/null || command -v sh 2>/dev/null || echo "/bin/sh")"
        if command -v runuser >/dev/null 2>&1; then
            runuser -u "$TARGET_USER" -- "$EXEC_SHELL" -c "
                set -e
                export USER='${TARGET_USER}'
                export HOME='/home/${TARGET_USER}'
                export PATH=\"/nix/var/nix/profiles/default/bin:/home/${TARGET_USER}/.nix-profile/bin:\$PATH\"
                export HOME_MANAGER_BACKUP_EXT=\"backup\"
                [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
                [ -f \"/home/${TARGET_USER}/.nix-profile/etc/profile.d/nix.sh\" ] && . \"/home/${TARGET_USER}/.nix-profile/etc/profile.d/nix.sh\" 2>/dev/null || true
                [ -L \"\$HOME/.config/nvim\" ] && rm -rf \"\$HOME/.config/nvim\"
                if command -v git >/dev/null 2>&1; then
                    git config --global --add safe.directory '${TARGET_DIR}' 2>/dev/null || true
                    git config --global --add safe.directory '*' 2>/dev/null || true
                fi
                cd '${TARGET_DIR}'
                for f in \"\$HOME/.zshrc\" \"\$HOME/.bashrc\" \"\$HOME/.bash_profile\" \"\$HOME/.profile\" \"\$HOME/.zshenv\" \"\$HOME/.vimrc\" \"\$HOME/.gitconfig\" \"\$HOME/.config/starship.toml\" \"\$HOME/.ssh/config\"; do
                    if [ -f \"\$f\" ] && [ ! -L \"\$f\" ]; then
                        mv \"\$f\" \"\${f}.backup\" 2>/dev/null || true
                    fi
                done
                CLEAN_TARGET=\"\$(echo '${FLAKE_TARGET}' | sed 's/^\.#//')\"
                nix build --extra-experimental-features 'nix-command flakes' \".#homeConfigurations.\\\"\$CLEAN_TARGET\\\".activationPackage\" --out-link \"\$HOME/.hm-result\"
                \"\$HOME/.hm-result/activate\"
                rm -f \"\$HOME/.hm-result\"
            " </dev/null
        else
            su -s "$EXEC_SHELL" "$TARGET_USER" -c "
                set -e
                export USER='${TARGET_USER}'
                export HOME='/home/${TARGET_USER}'
                export PATH=\"/nix/var/nix/profiles/default/bin:/home/${TARGET_USER}/.nix-profile/bin:\$PATH\"
                export HOME_MANAGER_BACKUP_EXT=\"backup\"
                [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
                [ -f \"/home/${TARGET_USER}/.nix-profile/etc/profile.d/nix.sh\" ] && . \"/home/${TARGET_USER}/.nix-profile/etc/profile.d/nix.sh\" 2>/dev/null || true
                [ -L \"\$HOME/.config/nvim\" ] && rm -rf \"\$HOME/.config/nvim\"
                if command -v git >/dev/null 2>&1; then
                    git config --global --add safe.directory '${TARGET_DIR}' 2>/dev/null || true
                    git config --global --add safe.directory '*' 2>/dev/null || true
                fi
                cd '${TARGET_DIR}'
                for f in \"\$HOME/.zshrc\" \"\$HOME/.bashrc\" \"\$HOME/.bash_profile\" \"\$HOME/.profile\" \"\$HOME/.zshenv\" \"\$HOME/.vimrc\" \"\$HOME/.gitconfig\" \"\$HOME/.config/starship.toml\" \"\$HOME/.ssh/config\"; do
                    if [ -f \"\$f\" ] && [ ! -L \"\$f\" ]; then
                        mv \"\$f\" \"\${f}.backup\" 2>/dev/null || true
                    fi
                done
                CLEAN_TARGET=\"\$(echo '${FLAKE_TARGET}' | sed 's/^\.#//')\"
                nix build --extra-experimental-features 'nix-command flakes' \".#homeConfigurations.\\\"\$CLEAN_TARGET\\\".activationPackage\" --out-link \"\$HOME/.hm-result\"
                \"\$HOME/.hm-result/activate\"
                rm -f \"\$HOME/.hm-result\"
            " </dev/null
        fi
    else
        export PATH="/nix/var/nix/profiles/default/bin:$HOME/.nix-profile/bin:$PATH"
        export HOME_MANAGER_BACKUP_EXT="backup"
        [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ] && . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
        [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ] && . "$HOME/.nix-profile/etc/profile.d/nix.sh" 2>/dev/null || true
        [ -L "$HOME/.config/nvim" ] && rm -rf "$HOME/.config/nvim"
        for f in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.zshenv" "$HOME/.vimrc" "$HOME/.gitconfig" "$HOME/.config/starship.toml" "$HOME/.ssh/config"; do
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

    # Create system-wide profile.d entry so Nix user profile is automatically in PATH on login
    if [ "$IS_ROOT" = true ] && [ -d /etc/profile.d ]; then
        cat << 'EOF' > /etc/profile.d/99-nix-path.sh
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh 2>/dev/null || true
fi
if [ -n "$HOME" ] && [ -d "$HOME/.nix-profile/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.nix-profile/bin:"*) ;;
        *) export PATH="$HOME/.nix-profile/bin:$PATH" ;;
    esac
fi
EOF
        chmod 644 /etc/profile.d/99-nix-path.sh
    fi

    # Update login shell to Zsh once Home Manager has installed zsh
    USER_HOME="/home/${TARGET_USER}"
    NIX_ZSH="${USER_HOME}/.nix-profile/bin/zsh"
    REAL_ZSH="$(readlink -f "$NIX_ZSH" 2>/dev/null || echo "$NIX_ZSH")"
    SYS_ZSH="$(command -v zsh 2>/dev/null || echo "")"

    # Register all possible Zsh paths in /etc/shells for PAM / chsh
    for zpath in "$NIX_ZSH" "$REAL_ZSH" "$SYS_ZSH" "/bin/zsh" "/usr/bin/zsh"; do
        if [ -n "$zpath" ] && [ -x "$zpath" ] && [ -f /etc/shells ]; then
            if ! grep -qF "$zpath" /etc/shells 2>/dev/null; then
                if [ "$IS_ROOT" = true ]; then
                    echo "$zpath" >> /etc/shells
                else
                    echo "$zpath" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
                fi
            fi
        fi
    done

    CHOSEN_ZSH=""
    if [ -x "$NIX_ZSH" ]; then
        CHOSEN_ZSH="$NIX_ZSH"
    elif [ -x "$SYS_ZSH" ]; then
        CHOSEN_ZSH="$SYS_ZSH"
    fi

    if [ -n "$CHOSEN_ZSH" ]; then
        log "${BLUE}==> Updating default login shell to ${CHOSEN_ZSH} for '${TARGET_USER}'...${NC}"
        if [ "$IS_ROOT" = true ]; then
            chsh -s "$CHOSEN_ZSH" "$TARGET_USER" 2>/dev/null || usermod -s "$CHOSEN_ZSH" "$TARGET_USER" 2>/dev/null || true
        else
            sudo chsh -s "$CHOSEN_ZSH" "$TARGET_USER" 2>/dev/null || chsh -s "$CHOSEN_ZSH" 2>/dev/null || true
        fi
    fi

    # Configure and start Grafana Alloy system service on non-NixOS hosts
    ALLOY_BIN="${USER_HOME}/.nix-profile/bin/alloy"
    ALLOY_CFG="${TARGET_DIR}/config/alloy/config.alloy"
    if [ "$IS_ROOT" = true ] && [ -x "$ALLOY_BIN" ] && [ -f "$ALLOY_CFG" ]; then
        log "${BLUE}==> Configuring Grafana Alloy log shipping to Loki...${NC}"
        mkdir -p /etc/alloy /var/lib/alloy /var/log/journal
        cp "$ALLOY_CFG" /etc/alloy/config.alloy
        chmod 644 /etc/alloy/config.alloy

        if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
            cat << EOF > /etc/systemd/system/alloy.service
[Unit]
Description=Grafana Alloy Log Collector
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=${ALLOY_BIN} run --storage.path=/var/lib/alloy /etc/alloy/config.alloy
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
            systemctl daemon-reload 2>/dev/null || true
            systemctl enable --now alloy.service 2>/dev/null || systemctl restart alloy.service 2>/dev/null || true
            log "${GREEN}==> Grafana Alloy systemd service enabled and running.${NC}"
        elif command -v rc-service >/dev/null 2>&1; then
            cat << EOF > /etc/init.d/alloy
#!/sbin/openrc-run
name="alloy"
description="Grafana Alloy Log Collector"
command="${ALLOY_BIN}"
command_args="run --storage.path=/var/lib/alloy /etc/alloy/config.alloy"
command_background="yes"
pidfile="/run/alloy.pid"
output_log="/var/log/alloy.log"
error_log="/var/log/alloy.err"

depend() {
    need net
    after firewall
}
EOF
            chmod +x /etc/init.d/alloy
            rc-update add alloy default 2>/dev/null || true
            rc-service alloy restart 2>/dev/null || rc-service alloy start 2>/dev/null || true
            log "${GREEN}==> Grafana Alloy OpenRC service enabled and running.${NC}"
        fi
    fi

    # Sync declarative Grafana provisioning (datasources & alert rules) if Grafana is installed on this host
    GRAFANA_PROV_SRC="${TARGET_DIR}/config/grafana/provisioning"
    GRAFANA_PROV_DST="/etc/grafana/provisioning"
    if [ "$IS_ROOT" = true ] && [ -d "$GRAFANA_PROV_DST" ] && [ -d "$GRAFANA_PROV_SRC" ]; then
        log "${BLUE}==> Grafana installation detected! Syncing declarative provisioning configs...${NC}"
        mkdir -p "${GRAFANA_PROV_DST}/datasources" "${GRAFANA_PROV_DST}/alerting"
        cp -rf "${GRAFANA_PROV_SRC}/datasources/." "${GRAFANA_PROV_DST}/datasources/" 2>/dev/null || true
        cp -rf "${GRAFANA_PROV_SRC}/alerting/." "${GRAFANA_PROV_DST}/alerting/" 2>/dev/null || true
        chown -R root:grafana "$GRAFANA_PROV_DST" 2>/dev/null || true
        chmod -R u+rwX,g+rX "$GRAFANA_PROV_DST" 2>/dev/null || true
        systemctl restart grafana-server 2>/dev/null || service grafana-server restart 2>/dev/null || true
        log "${GREEN}==> Grafana datasources & alert rules provisioned and service reloaded.${NC}"
    fi

    # Configure and start GitOps auto-sync timer (checks every 15m for new commits)
    GITOPS_SRC="${TARGET_DIR}/scripts/gitops-sync.sh"
    GITOPS_BIN="/usr/local/bin/dotfiles-gitops-sync"
    if [ "$IS_ROOT" = true ] && [ -f "$GITOPS_SRC" ]; then
        log "${BLUE}==> Configuring GitOps auto-sync timer (every 15m)...${NC}"
        mkdir -p /usr/local/bin
        cp "$GITOPS_SRC" "$GITOPS_BIN"
        chmod 755 "$GITOPS_BIN"

        if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
            cat << 'EOF' > /etc/systemd/system/dotfiles-gitops.service
[Unit]
Description=Dotfiles GitOps Auto-Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/dotfiles-gitops-sync
EOF
            cat << 'EOF' > /etc/systemd/system/dotfiles-gitops.timer
[Unit]
Description=Run Dotfiles GitOps Auto-Sync every 15 minutes

[Timer]
OnBootSec=3min
OnCalendar=*:0/15
RandomizedDelaySec=60
Persistent=true

[Install]
WantedBy=timers.target
EOF
            systemctl daemon-reload 2>/dev/null || true
            systemctl enable --now dotfiles-gitops.timer 2>/dev/null || true
            log "${GREEN}==> GitOps systemd timer (dotfiles-gitops.timer) enabled.${NC}"
        elif command -v rc-service >/dev/null 2>&1; then
            mkdir -p /etc/periodic/15min
            ln -sf "$GITOPS_BIN" /etc/periodic/15min/dotfiles-gitops
            rc-update add crond default 2>/dev/null || true
            rc-service crond start 2>/dev/null || true
            log "${GREEN}==> GitOps OpenRC 15-minute periodic job enabled.${NC}"
        fi
    fi

    # Clean up old Nix store generations to reclaim disk space automatically
    log "${BLUE}==> Purging unneeded Nix packages to reclaim disk space...${NC}"
    if command -v nix-collect-garbage >/dev/null 2>&1; then
        nix-collect-garbage -d 2>/dev/null || true
    elif [ -x /nix/var/nix/profiles/default/bin/nix-collect-garbage ]; then
        /nix/var/nix/profiles/default/bin/nix-collect-garbage -d 2>/dev/null || true
    fi

    log "${GREEN}===================================================================${NC}"
    log "${GREEN}  Proxmox (${OS_ID}) Bootstrapping Completed Successfully!           ${NC}"
    log "${GREEN}  User '${TARGET_USER}' created with SSH key & passwordless sudo. ${NC}"
    log "${GREEN}===================================================================${NC}"
fi
