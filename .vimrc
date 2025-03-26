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
Plugin 'itchyny/lightline.vim'
" ... with git
Plugin 'itchyny/vim-gitbranch.vim'
" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required for vundle
" Configure status line
let g:lightline = {
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'gitbranch#name'
      \ },
      \ }

" crontab configuration
au BufEnter /tmp/crontab.* setl backupcopy=yes
autocmd filetype crontab setlocal nobackup nowritebackup

" Use external editorconfig
let g:EditorConfig_exec_path = '/usr/local/bin/editorconfig'
let g:EditorConfig_core_mode = 'external_command'
" set lightline status line visible
set laststatus=2

au BufRead, BufNewFile *.py,*.pyw,*.c,*.h match BadWhitespace /\s\+$/
set encoding=utf-8

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

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal

