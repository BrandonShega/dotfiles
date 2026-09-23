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
      catppuccin
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

      # Catppuccin Theme Config (Mocha)
      set -g @catppuccin_flavor 'mocha'
      set -g @catppuccin_window_status_style 'rounded'

      # Resurrect & Continuum defaults
      set -g @resurrect-capture-pane-contents 'on'
      set -g @continuum-restore 'on'
    '';
  };
}
