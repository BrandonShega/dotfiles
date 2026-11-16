#!/usr/bin/env bash

# Lightweight GitOps poller for non-NixOS Proxmox LXCs & VMs
# Exits immediately if local HEAD matches origin/main; otherwise runs proxmox-bootstrap.sh
set -e
(set -o pipefail 2>/dev/null) && set -o pipefail || true

export HOME="${HOME:-/root}"
export USER="${USER:-root}"
export PATH="/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

OS_ID="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="${ID:-unknown}"
fi

TARGET_USER="smoochii"
if [ "$OS_ID" = "kali" ]; then
    TARGET_USER="kali"
fi

TARGET_DIR="/home/${TARGET_USER}/.config/dotfiles"
if [ ! -d "$TARGET_DIR/.git" ]; then
    exit 0
fi

cd "$TARGET_DIR"

GITEA_URL="https://gitea.smoochii.dev/smoochii/dotfiles.git"
GITHUB_FALLBACK_URL="https://github.com/BrandonShega/dotfiles.git"
ACTIVE_REPO_URL="$GITHUB_FALLBACK_URL"
if curl -kfsSLI --connect-timeout 2 --max-time 3 "$GITEA_URL" >/dev/null 2>&1; then
    ACTIVE_REPO_URL="$GITEA_URL"
fi

git -c safe.directory="*" remote set-url origin "$ACTIVE_REPO_URL" 2>/dev/null || true
if ! git -c safe.directory="*" -c http.connectTimeout=5 fetch origin main 2>/dev/null; then
    git -c safe.directory="*" remote set-url origin "$GITHUB_FALLBACK_URL" 2>/dev/null || true
    git -c safe.directory="*" -c http.connectTimeout=5 fetch origin main 2>/dev/null || exit 0
fi

LOCAL_REV="$(git -c safe.directory="*" rev-parse HEAD 2>/dev/null || echo "")"
REMOTE_REV="$(git -c safe.directory="*" rev-parse origin/main 2>/dev/null || echo "")"

if [ -n "$LOCAL_REV" ] && [ -n "$REMOTE_REV" ] && [ "$LOCAL_REV" = "$REMOTE_REV" ]; then
    exit 0
fi

echo "[dotfiles-gitops] New commit detected (${LOCAL_REV:-none} -> ${REMOTE_REV:-unknown}). Applying update..."
git -c safe.directory="*" reset --hard origin/main

if command -v bash >/dev/null 2>&1; then
    bash "$TARGET_DIR/scripts/proxmox-bootstrap.sh" </dev/null
else
    sh "$TARGET_DIR/scripts/proxmox-bootstrap.sh" </dev/null
fi
