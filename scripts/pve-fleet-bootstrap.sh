#!/usr/bin/env bash

# Proxmox VE Fleet Bootstrapper
# Run this on your Proxmox VE host (pve) to automatically bootstrap all LXC containers & QEMU VMs!
export PATH="/usr/sbin:/sbin:/usr/bin:/bin:$PATH"

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo -e "${RED}Error: pve-fleet-bootstrap.sh must be run as root or with sudo!${NC}"
    echo -e "${YELLOW}Usage: sudo curl -sSLk ... | sudo bash${NC}"
    exit 1
fi

echo -e "${BLUE}===================================================================${NC}"
echo -e "${BLUE}        Proxmox VE Fleet Bootstrap Automation                      ${NC}"
echo -e "${BLUE}===================================================================${NC}"

# Resolve IP of gitea.smoochii.dev on PVE host for containers with DNS issues
GITEA_DOMAIN="gitea.smoochii.dev"
GITEA_IP=$(getent hosts "$GITEA_DOMAIN" 2>/dev/null | awk '{print $1}' || getent ahostsv4 "$GITEA_DOMAIN" 2>/dev/null | awk 'NR==1 {print $1}' || echo "10.10.1.102")
GITEA_IP="${GITEA_IP:-10.10.1.102}"

if [ -n "$GITEA_IP" ]; then
    echo -e "${GREEN}==> Resolved ${GITEA_DOMAIN} -> ${GITEA_IP}${NC}"
fi

# 1. Bootstrap LXC Containers
if command -v pct &>/dev/null; then
    echo -e "\n${YELLOW}==> Discovering LXC Containers on PVE host...${NC}"
    LXC_IDS=$(pct list 2>/dev/null | awk 'NR>1 {print $1}')

    if [ -z "$LXC_IDS" ]; then
        echo -e "${BLUE}No LXC containers found.${NC}"
    else
        for vmid in $LXC_IDS; do
            STATUS=$(pct status "$vmid" 2>/dev/null | awk '{print $2}')
            NAME=$(pct config "$vmid" 2>/dev/null | grep -i "^hostname:" | awk '{print $2}')
            
            if [ "$STATUS" = "running" ]; then
                echo -e "${GREEN}===> Bootstrapping LXC CT $vmid (${NAME:-unnamed})...${NC}"
                pct exec "$vmid" -- sh -c "export GITEA_IP='${GITEA_IP}'; curl -sSLk ${BOOTSTRAP_URL} | sh" || echo -e "${RED}Failed on CT $vmid${NC}"
            else
                echo -e "${YELLOW}Skipping stopped LXC CT $vmid (${NAME:-unnamed})${NC}"
            fi
        done
    fi
fi

# 2. Bootstrap QEMU VMs (via QEMU Guest Agent)
if command -v qm &>/dev/null; then
    echo -e "\n${YELLOW}==> Discovering QEMU VMs on PVE host...${NC}"
    VM_IDS=$(qm list 2>/dev/null | awk 'NR>1 {print $1}')

    if [ -z "$VM_IDS" ]; then
        echo -e "${BLUE}No QEMU VMs found.${NC}"
    else
        for vmid in $VM_IDS; do
            STATUS=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')
            NAME=$(qm config "$vmid" 2>/dev/null | grep -i "^name:" | awk '{print $2}')

            if [ "$STATUS" = "running" ]; then
                echo -e "${GREEN}===> Attempting QEMU Guest Exec on VM $vmid (${NAME:-unnamed})...${NC}"
                if qm guest cmd "$vmid" ping &>/dev/null; then
                    qm guest exec "$vmid" -- sh -c "export GITEA_IP='${GITEA_IP}'; curl -sSLk ${BOOTSTRAP_URL} | sh" || echo -e "${RED}Failed on VM $vmid${NC}"
                else
                    echo -e "${YELLOW}QEMU Guest Agent not responding on VM $vmid (${NAME:-unnamed}). Skipping.${NC}"
                fi
            else
                echo -e "${YELLOW}Skipping stopped VM $vmid (${NAME:-unnamed})${NC}"
            fi
        done
    fi
fi

echo -e "\n${GREEN}===================================================================${NC}"
echo -e "${GREEN}  Proxmox VE Fleet Bootstrapping Complete!                         ${NC}"
echo -e "${GREEN}===================================================================${NC}"
