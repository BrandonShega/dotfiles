local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

config.color_scheme = "Tokyo Night Storm"

config.font = wezterm.font("MonaspiceNe Nerd Font")

config.window_decorations = "RESIZE"
config.window_background_opacity = 0.75
config.macos_window_background_blur = 8

config.enable_tab_bar = false

config.keys = {}
table.insert(config.keys, {
	key = "ENTER",
	mods = "CMD",
	action = act.ActivateWindow(0),
})

return config
