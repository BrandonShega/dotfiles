{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Native Home Manager keymap selection
    defaultKeymap = "emacs";

    history = {
      size = 5000;
      save = 5000;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      ignoreDups = true;
    };

    shellAliases = {
      md = "mkdir -p";
      rd = "rmdir";
      "cd.." = "cd ..";
      ".." = "cd ..";
      l = "eza --all --oneline --long --icons=always";
      lt = "eza --all --oneline --tree --icons=always";
      kali = "ssh ssh.kali";
      kali-proxy = "ssh ssh.kali -D 8089";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "docker"
        "git"
        "kubectl"
        "kubectx"
        "sudo"
        "virtualenv"
      ];
    };

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    initContent = ''
      # Prevent zsh-autosuggestions and zsh-syntax-highlighting ZLE widget double-binding collision
      export ZSH_AUTOSUGGEST_MANUAL_REBIND=1
      export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"

      # Ensure valid UTF-8 locale for Zsh Line Editor (ZLE) width calculations
      export LANG="C.UTF-8"
      export LC_ALL="C.UTF-8"

      # Custom keybindings
      bindkey '^k' history-search-backward
      bindkey '^j' history-search-forward
      bindkey '^f' autosuggest-accept

      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        # Linux-specific keyboard mappings (evaluated by Nix at compile time)
        if [ -n "$DISPLAY" ]; then
            setxkbmap -option 'caps:ctrl_modifier'
            xcape -e 'Caps_Lock=Escape' -t 100
        fi
      ''}

      # Import Local zshrc if exists
      [[ ! -a "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"
    '';

    envExtra = ''
      # Fallback TERM to xterm-256color if host lacks terminfo (e.g. xterm-ghostty / alacritty on bare PVE hosts)
      if [ -n "$TERM" ] && command -v infocmp &>/dev/null && ! infocmp "$TERM" &>/dev/null; then
          export TERM=xterm-256color
      fi

      # Import Local env if exists
      [[ ! -a "$HOME/.zshenv.local" ]] || source "$HOME/.zshenv.local"
    '';
  };

  # Automatically switch from Bash to Zsh for interactive sessions
  programs.bash = {
    enable = true;
    initExtra = ''
      if [ -t 1 ] && command -v zsh &>/dev/null && [ -z "$ZSH_VERSION" ]; then
        exec zsh -l
      fi
    '';
  };

  # Configure additional shell utilities
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableZshIntegration = true;
  };

  home.sessionPath = [
    "$HOME/.rvm/bin"
    "$HOME/.bin"
    "$HOME/.local/bin"
    "$HOME/.composer/vendor/bin"
    "$HOME/Documents/flutter/bin"
    "$HOME/.emacs.d/bin"
    "$HOME/go/bin"
    "$HOME/.pyenv/bin"
    "$HOME/.pyenv/shims"
    "$HOME/.emacs-configs/doom-emacs/bin"
  ];
}
