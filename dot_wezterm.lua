local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.color_scheme = "Catppuccin Frappe"

config.font = wezterm.font("MonaspiceNe Nerd Font")

config.window_decorations = "RESIZE"

config.enable_tab_bar = false

config.default_prog = { "/usr/bin/zsh" }

return config
