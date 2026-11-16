#!/usr/bin/env bash

# Proxmox VE Fleet Bootstrapper
# Run this on your Proxmox VE host (pve) to automatically bootstrap all LXC containers & QEMU VMs!
export PATH="/usr/sbin:/sbin:/usr/bin:/bin:$PATH"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    printf "%b\n" "$1"
}

if [ "$(id -u)" -ne 0 ]; then
    log "${RED}Error: pve-fleet-bootstrap.sh must be run as root or with sudo!${NC}"
    log "${YELLOW}Usage: sudo curl -sSLk ... | sudo bash${NC}"
    exit 1
fi

log "${BLUE}===================================================================${NC}"
log "${BLUE}        Proxmox VE Fleet Bootstrap Automation                      ${NC}"
log "${BLUE}===================================================================${NC}"

# Resolve IP of gitea.smoochii.dev on PVE host for containers with DNS issues
GITEA_DOMAIN="gitea.smoochii.dev"
GITEA_IP=$(getent hosts "$GITEA_DOMAIN" 2>/dev/null | awk '{print $1}' || getent ahostsv4 "$GITEA_DOMAIN" 2>/dev/null | awk 'NR==1 {print $1}' || echo "10.10.10.109")
CACHE_BUST="$(date +%s)"
BOOTSTRAP_URL="${BOOTSTRAP_URL:-https://raw.githubusercontent.com/brandonshega/dotfiles/main/scripts/proxmox-bootstrap.sh}?t=${CACHE_BUST}"

REMOTE_CMD="export HOME=/root USER=root GITEA_IP='${GITEA_IP}'; curl -fsSLk '${BOOTSTRAP_URL}' -o /tmp/proxmox-bootstrap.sh && chmod +x /tmp/proxmox-bootstrap.sh && if command -v bash >/dev/null 2>&1; then bash /tmp/proxmox-bootstrap.sh </dev/null; else sh /tmp/proxmox-bootstrap.sh </dev/null; fi; rm -f /tmp/proxmox-bootstrap.sh"

# 1. Bootstrap LXC Containers
if command -v pct >/dev/null 2>&1; then
    log "\n${YELLOW}==> Discovering LXC Containers on PVE host...${NC}"
    LXC_IDS=$(pct list 2>/dev/null | awk 'NR>1 {print $1}')

    if [ -z "$LXC_IDS" ]; then
        log "${BLUE}No LXC containers found.${NC}"
    else
        for vmid in $LXC_IDS; do
            STATUS=$(pct status "$vmid" 2>/dev/null | awk '{print $2}')
            NAME=$(pct config "$vmid" 2>/dev/null | grep -i "^hostname:" | awk '{print $2}')

            if [ "$STATUS" = "running" ]; then
                log "${GREEN}===> Bootstrapping LXC CT $vmid (${NAME:-unnamed})...${NC}"
                pct exec "$vmid" -- sh -c "$REMOTE_CMD" || log "${RED}Failed on CT $vmid${NC}"
            else
                log "${YELLOW}Skipping stopped LXC CT $vmid (${NAME:-unnamed})${NC}"
            fi
        done
    fi
fi

# 2. Bootstrap QEMU VMs (via QEMU Guest Agent)
if command -v qm >/dev/null 2>&1; then
    log "\n${YELLOW}==> Discovering QEMU VMs on PVE host...${NC}"
    VM_IDS=$(qm list 2>/dev/null | awk 'NR>1 {print $1}')

    if [ -z "$VM_IDS" ]; then
        log "${BLUE}No QEMU VMs found.${NC}"
    else
        for vmid in $VM_IDS; do
            STATUS=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')
            NAME=$(qm config "$vmid" 2>/dev/null | grep -i "^name:" | awk '{print $2}')

            if [ "$STATUS" = "running" ]; then
                log "${GREEN}===> Attempting QEMU Guest Exec on VM $vmid (${NAME:-unnamed})...${NC}"
                if qm guest cmd "$vmid" ping >/dev/null 2>&1; then
                    qm guest exec "$vmid" -- sh -c "$REMOTE_CMD" || log "${RED}Failed on VM $vmid${NC}"
                else
                    log "${YELLOW}QEMU Guest Agent not responding on VM $vmid (${NAME:-unnamed}). Skipping.${NC}"
                fi
            else
                log "${YELLOW}Skipping stopped VM $vmid (${NAME:-unnamed})${NC}"
            fi
        done
    fi
fi

log "\n${GREEN}===================================================================${NC}"
log "${GREEN}  Proxmox VE Fleet Bootstrapping Complete!                         ${NC}"
log "${GREEN}===================================================================${NC}"
