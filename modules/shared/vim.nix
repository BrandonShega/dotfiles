{ config, pkgs, ... }:

{
  programs.vim = {
    enable = true;
    defaultEditor = true;
    settings = {
      number = true;
      relativenumber = false;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartcase = true;
      ignorecase = true;
    };
    extraConfig = ''
      syntax on
      set mouse=a
      set termguicolors
      set backspace=indent,eol,start
      set background=dark
      set encoding=utf-8
      set history=1000
      set undofile
      set wildmenu
      set hlsearch
      set incsearch

      " Shortcut to clear search highlights
      nnoremap <silent> <C-l> :nohlsearch<CR><C-l>
    '';
  };
}
