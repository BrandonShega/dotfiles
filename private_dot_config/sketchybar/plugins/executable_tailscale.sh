#!/bin/sh

# Toggles between tailscale being on and off.

update_button() {
  if [ "$RUNNING" = true ]; then
    sketchybar --set "$NAME" label="VPN ON" icon.drawing=on icon= background.color=0xffB3E1A7
  else
    sketchybar --set "$NAME" label="VPN OFF" icon.drawing=off background.color=0xffef9f76
  fi
}

STATUS=$(tailscale status)
RUNNING=false

if [ ! "$(command -v tailscale)" ]; then
  update_button
  exit
fi

if [ ! "$STATUS" = "Tailscale is stopped." ]; then
  RUNNING=true
fi

update_button

if [ "$SENDER" = "tailscale" ]; then
  if [ "$RUNNING" = true ]; then
    tailscale down
    RUNNING=false
    update_button
  else
    tailscale up
    RUNNING=true
    update_button
  fi
fi
