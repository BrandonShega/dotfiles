#!/usr/bin/env bash

# Daily Homelab Update Checker (OS Packages + Docker Container Images)
# Logs structured update summaries to systemd-journal (syslog_identifier=homelab-updates)
# which Grafana Alloy ships to Loki -> Grafana -> Discord.
set -e
(set -o pipefail 2>/dev/null) && set -o pipefail || true

export HOME="${HOME:-/root}"
export USER="${USER:-root}"
export PATH="/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

HOSTNAME_STR="$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown-host")"

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
