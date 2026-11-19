#!/usr/bin/env bash

# Daily Homelab Update Checker (OS Packages + Docker Containers + Standalone LXC Apps)
# Logs structured update summaries to systemd-journal (syslog_identifier=homelab-updates)
# which Grafana Alloy ships to Loki -> Grafana -> Discord.
set -e
(set -o pipefail 2>/dev/null) && set -o pipefail || true

export HOME="${HOME:-/root}"
export USER="${USER:-root}"
export PATH="/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

HOSTNAME_STR="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown-host")"

# Helper to query latest GitHub release tag (strips leading 'v')
gh_latest_version() {
    REPO="$1"
    curl -fsSLm 5 "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
        | awk -F'"' '/"tag_name":/ {gsub(/^v/, "", $4); print $4; exit}' || true
}

# 1. Check OS Package Updates (Debian/Ubuntu/Kali/PVE via apt, or Alpine via apk)
OS_UPDATES_COUNT=0
OS_SAMPLE_PKGS=""

if command -v apt-get >/dev/null 2>&1; then
    apt-get update -qq 2>/dev/null || true
    UPGRADABLE_LIST="$(apt-get -s -o Debug::NoLocking=true upgrade 2>/dev/null | awk '/^Inst / {print $2}' || true)"
    if [ -n "$UPGRADABLE_LIST" ]; then
        OS_UPDATES_COUNT="$(printf "%s\n" "$UPGRADABLE_LIST" | wc -l | tr -d ' ')"
        OS_SAMPLE_PKGS="$(printf "%s\n" "$UPGRADABLE_LIST" | head -n 6 | tr '\n' ' ' | sed 's/ $//')"
    fi
elif command -v apk >/dev/null 2>&1; then
    apk update -q 2>/dev/null || true
    UPGRADABLE_LIST="$(apk version -l '<' 2>/dev/null | sed 1d | awk '{print $1}' || true)"
    if [ -n "$UPGRADABLE_LIST" ]; then
        OS_UPDATES_COUNT="$(printf "%s\n" "$UPGRADABLE_LIST" | wc -l | tr -d ' ')"
        OS_SAMPLE_PKGS="$(printf "%s\n" "$UPGRADABLE_LIST" | head -n 6 | tr '\n' ' ' | sed 's/ $//')"
    fi
fi

if [ "${OS_UPDATES_COUNT:-0}" -gt 0 ]; then
    MSG="UPDATES_AVAILABLE: host=${HOSTNAME_STR} type=os count=${OS_UPDATES_COUNT} packages=\"${OS_SAMPLE_PKGS}\""
    logger -p daemon.notice -t homelab-updates "$MSG" 2>/dev/null || echo "$MSG"
fi

# 2. Check Running Docker Containers for Newer Registry Image Digests
if command -v docker >/dev/null 2>&1 && [ -S /var/run/docker.sock ]; then
    UPDATED_CONTAINERS=""
    DOCKER_UPDATES_COUNT=0

    for entry in $(docker ps --format '{{.Names}}|{{.Image}}' 2>/dev/null || true); do
        C_NAME="${entry%%|*}"
        C_IMAGE="${entry#*|}"

        # Compare local RepoDigest with remote registry manifest digest (without pulling layers)
        LOCAL_DIGESTS="$(docker image inspect --format '{{join .RepoDigests " "}}' "$C_IMAGE" 2>/dev/null || true)"
        REMOTE_DIGEST="$(docker buildx imagetools inspect --raw "$C_IMAGE" 2>/dev/null | sha256sum 2>/dev/null | awk '{print "sha256:"$1}' || true)"

        if [ -n "$LOCAL_DIGESTS" ] && [ -n "$REMOTE_DIGEST" ] && [ "$REMOTE_DIGEST" != "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" ]; then
            case "$LOCAL_DIGESTS" in
                *"$REMOTE_DIGEST"*) ;;
                *)
                    DOCKER_UPDATES_COUNT=$((DOCKER_UPDATES_COUNT + 1))
                    UPDATED_CONTAINERS="${UPDATED_CONTAINERS}${C_NAME}(${C_IMAGE}) "
                    ;;
            esac
        fi
    done

    if [ "${DOCKER_UPDATES_COUNT:-0}" -gt 0 ]; then
        CLEAN_CONTAINERS="$(echo "$UPDATED_CONTAINERS" | sed 's/ $//')"
        MSG="UPDATES_AVAILABLE: host=${HOSTNAME_STR} type=docker count=${DOCKER_UPDATES_COUNT} containers=\"${CLEAN_CONTAINERS}\""
        logger -p daemon.notice -t homelab-updates "$MSG" 2>/dev/null || echo "$MSG"
    fi
fi

# 3. Check Standalone LXC Applications (Vaultwarden/Bitwarden, Pi-hole, Gitea, Uptime Kuma, Pterodactyl)
APP_UPDATES_COUNT=0
UPDATED_APPS=""

# 3a. Vaultwarden / Bitwarden (LXC 101: vault)
VW_VER=""
for vw_bin in /opt/vaultwarden/target/release/vaultwarden /opt/vaultwarden/bin/vaultwarden /usr/local/bin/vaultwarden /usr/bin/vaultwarden; do
    if [ -x "$vw_bin" ]; then
        VW_VER="$("$vw_bin" --version 2>/dev/null | awk '{gsub(/^v/, "", $2); print $2; exit}' || true)"
        [ -n "$VW_VER" ] && break
    fi
done
if [ -z "$VW_VER" ] && [ -f /opt/vaultwarden_version.txt ]; then
    VW_VER="$(head -n1 /opt/vaultwarden_version.txt 2>/dev/null | tr -d 'v \r\n' || true)"
elif [ -z "$VW_VER" ] && [ -d /opt/vaultwarden/.git ]; then
    VW_VER="$(git -C /opt/vaultwarden describe --tags 2>/dev/null | sed 's/^v//' || true)"
fi
if [ -n "$VW_VER" ]; then
    VW_LATEST="$(gh_latest_version "dani-garcia/vaultwarden")"
    if [ -n "$VW_LATEST" ] && [ "$VW_VER" != "$VW_LATEST" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}vaultwarden(${VW_VER}->${VW_LATEST}) "
    fi
fi

# 3b. Pi-hole (LXC 106: pihole)
if command -v pihole >/dev/null 2>&1; then
    PH_OUT="$(pihole -v 2>/dev/null || true)"
    PH_UPDATES="$(printf "%s\n" "$PH_OUT" | awk '
        /version is/ && /Latest:/ {
            comp=$1; cur=$4; lat=$6;
            gsub(/[()v]/, "", cur); gsub(/[()v]/, "", lat);
            if (cur != "" && lat != "" && lat != "N/A" && cur != lat) {
                printf "%s(%s->%s) ", comp, cur, lat
            }
        }
    ' || true)"
    if [ -n "$PH_UPDATES" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}pihole:${PH_UPDATES}"
    fi
fi

# 3c. Gitea (LXC 109: gitea)
GITEA_BIN="$(command -v gitea 2>/dev/null || echo "")"
[ -z "$GITEA_BIN" ] && [ -x /usr/local/bin/gitea ] && GITEA_BIN="/usr/local/bin/gitea"
if [ -n "$GITEA_BIN" ]; then
    GT_VER="$("$GITEA_BIN" --version 2>/dev/null | awk '{gsub(/^v/, "", $3); print $3; exit}' || true)"
    GT_LATEST="$(gh_latest_version "go-gitea/gitea")"
    if [ -n "$GT_VER" ] && [ -n "$GT_LATEST" ] && [ "$GT_VER" != "$GT_LATEST" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}gitea(${GT_VER}->${GT_LATEST}) "
    fi
fi

# 3d. Uptime Kuma (LXC 122: uptimekuma)
if [ -f /opt/uptime-kuma/package.json ]; then
    UK_VER="$(awk -F'"' '/"version":/ {print $4; exit}' /opt/uptime-kuma/package.json 2>/dev/null || true)"
    UK_LATEST="$(gh_latest_version "louislam/uptime-kuma")"
    if [ -n "$UK_VER" ] && [ -n "$UK_LATEST" ] && [ "$UK_VER" != "$UK_LATEST" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}uptime-kuma(${UK_VER}->${UK_LATEST}) "
    fi
fi

# 3e. Pterodactyl Panel (LXC 107: panel) & Wings (LXC 108: gaming)
if [ -f /var/www/pterodactyl/config/app.php ]; then
    PT_VER="$(awk -F"'" '/'\''version'\''[[:space:]]*=>/ {print $4; exit}' /var/www/pterodactyl/config/app.php 2>/dev/null | sed 's/^v//' || true)"
    PT_LATEST="$(gh_latest_version "pterodactyl/panel")"
    if [ -n "$PT_VER" ] && [ -n "$PT_LATEST" ] && [ "$PT_VER" != "$PT_LATEST" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}pterodactyl-panel(${PT_VER}->${PT_LATEST}) "
    fi
fi
if [ -x /usr/local/bin/wings ]; then
    WG_VER="$(/usr/local/bin/wings --version 2>/dev/null | awk '{gsub(/^v/, "", $NF); print $NF; exit}' || true)"
    WG_LATEST="$(gh_latest_version "pterodactyl/wings")"
    if [ -n "$WG_VER" ] && [ -n "$WG_LATEST" ] && [ "$WG_VER" != "$WG_LATEST" ]; then
        APP_UPDATES_COUNT=$((APP_UPDATES_COUNT + 1))
        UPDATED_APPS="${UPDATED_APPS}pterodactyl-wings(${WG_VER}->${WG_LATEST}) "
    fi
fi

if [ "${APP_UPDATES_COUNT:-0}" -gt 0 ]; then
    CLEAN_APPS="$(echo "$UPDATED_APPS" | sed 's/ $//')"
    MSG="UPDATES_AVAILABLE: host=${HOSTNAME_STR} type=app count=${APP_UPDATES_COUNT} apps=\"${CLEAN_APPS}\""
    logger -p daemon.notice -t homelab-updates "$MSG" 2>/dev/null || echo "$MSG"
fi
