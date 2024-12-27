local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Frappe"
config.font = wezterm.font("MonaspiceNe Nerd Font")
config.font_size = 14
config.window_decorations = "RESIZE"
config.enable_tab_bar = false

return config
