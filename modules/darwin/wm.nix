{ pkgs, ... }:

{
  # Enable yabai tiling window manager daemon
  services.yabai = {
    enable = true;
    enableScriptingAddition = true;
  };

  # Enable skhd hotkey daemon
  services.skhd = {
    enable = true;
  };

  # Enable sketchybar status bar daemon
  services.sketchybar = {
    enable = true;
  };
}
