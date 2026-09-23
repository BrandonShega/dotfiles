{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "Space";
    keyMode = "vi";
    baseIndex = 1;
    escapeTime = 10;
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      tpm
      vim-tmux-navigator
      resurrect
      continuum
    ];

    extraConfig = ''
      # Add RGB support
      set-option -g terminal-overrides ',xterm-256color:RGB'

      # Split windows using | and -
      unbind %
      bind | split-window -h
      unbind '"'
      bind - split-window -v

      # Reload config
      unbind r
      bind r source-file ~/.tmux.conf

      # Pane navigation / resizing
      bind j resize-pane -D 5
      bind k resize-pane -U 5
      bind l resize-pane -R 5
      bind h resize-pane -L 5
      bind -r m resize-pane -Z

      # Mouse support
      set -g mouse on
      setw -g pane-base-index 1
      set-option -g renumber-windows on

      # Copy mode vi
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # Status bar options
      set -g status-position top

      # Theme config parameters
      set -g @powerline-color-main-1 colour4
      set -g @powerline-color-main-2 colour4
      set -g @powerline-color-main-3 colour4
      set -g @powerline-color-grey-1 "#232634"
      set -g @powerline-color-grey-2 "#40455A"
      set -g @powerline-status-left-area-left-bg colour4
      set -g @powerline-status-left-area-left-fg "#282C3D"
      set -g @powerline-status-right-area-right-bg colour4
      set -g @powerline-status-right-area-right-fg "#282C3D"
      set -g @powerline-status-left-area-middle-bg "#40455A"
      set -g @powerline-status-left-area-middle-fg colour4
      set -g @powerline-status-right-area-middle-bg "#40455A"
      set -g @powerline-status-right-area-middle-fg colour4
      set -g @powerline-status-left-area-right-bg "#282C3D"
      set -g @powerline-status-left-area-right-fg "#c6d0f5"
      set -g @powerline-status-right-area-left-bg "#282C3D"
      set -g @powerline-status-right-area-left-fg "#c6d0f5"
      set -g @theme-window-status-current-bg colour1
      set -g @theme-window-status-current-fg "#40455A"

      set -g @themepack 'powerline/double/blue'

      # Resurrect & Continuum defaults
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
    '';
  };
}
