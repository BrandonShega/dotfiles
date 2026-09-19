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
        "command-not-found"
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
      # Reset terminal line discipline to prevent double-echo on PVE / serial consoles
      stty sane 2>/dev/null || true

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
      # Import Local env if exists
      [[ ! -a "$HOME/.zshenv.local" ]] || source "$HOME/.zshenv.local"
    '';
  };

  # Automatically switch from Bash to Zsh for interactive sessions
  programs.bash = {
    enable = true;
    initExtra = ''
      if [ -t 1 ] && command -v zsh &>/dev/null && [ -z "$ZSH_VERSION" ]; then
        exec zsh
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
