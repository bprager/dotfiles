set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Vundle plugins
" EditorConfig Vim Plugin
Plugin 'editorconfig/editorconfig-vim'
" Light statusline
Plugin 'vim-airline/vim-airline'
" All of your Plugins must be added before the following line
call vundle#end()            " required

filetype plugin indent on    " required
" Put your non-Plugin settings after this line
scriptencoding utf-8
syntax enable

" Return to last edit position when opening files
autocmd BufReadPost *
      \ if line("'\"") > 0 && line("'\"") <= line("$") |
      \   exe "normal! g`\"" |
      \ endif

" User defined commands
command! Mask :s/"\([^"]*\)"/\='"' . repeat('*', len(submatch(1))) . '"'/g

" Disable line numbers after all plugins have loaded
set nonumber                  " no line numbers
