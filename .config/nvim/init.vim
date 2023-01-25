let mapleader="\<Space>"
    let $BASH_ENV = "~/.config/zsh/.aliases"
    set mouse=a
    set nohlsearch
    set nocompatible
    filetype plugin on
    syntax on
    set encoding=utf-8
    set number relativenumber
    set splitbelow splitright
    set clipboard+=unnamedplus

" Autocompletion
    set wildmode=longest,list,full

" Disable autocommenting
    autocmd FileType * setlocal formatoptions-=c formatoptions-=o formatoptions-=r

" Check file with shellcheck
    nmap <leader>s :!clear && shellcheck %<CR>

" Autoremove/highlight trailing whitespace
    autocmd BufWritePost * %s/\s\+$//e
    highlight ExtraWhitespace ctermbg=red guibg=red
    match ExtraWhitespace /\s\+$/
    au BufWinEnter * match ExtraWhitespace /\s\+$/
    au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
    au InsertLeave * match ExtraWhitespace /\s\+$/
    au BufWinLeave * call clearmatches()

" Run xrdb when I edit X files
    autocmd BufWritePost ~/.Xresources !xrdb %
    autocmd BufWritePost ~/.colors/xcolors !xrdb %
    autocmd BufWritePost ~/.Xdefaults !xrdb %

" Copy selected text to system clipboard
    vnoremap <C-c> "+y
    map <C-p> "+P

" Map jj in insert mode to quickly escape
    inoremap jj <Esc>

" I always hit semicolon
    noremap ; :

" Quick write/quit
    noremap qq :q<cr>
    noremap ww :w<cr>
    noremap wq :wq<cr>
    noremap q1 :q!<cr>

" Reload config
    nnoremap <leader>sv :source ~/.config/nvim/init.vim<CR>

" Tab is 4 spaces
    set softtabstop=4
    set shiftwidth=4
    set noexpandtab
