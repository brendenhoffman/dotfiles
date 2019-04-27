let mapleader=" "
	let $BASH_ENV = "~/.bash_aliases"
	set mouse=a
	set nohlsearch
	set nocompatible
	filetype plugin on
	syntax on
	set encoding=utf-8
	set number relativenumber
	set splitbelow splitright

" Autocompletion
	set wildmode=longest,list,full

" Disable autocommenting
	autocmd FileType * setlocal formatoptions-=c formatoptions-=o formatoptions-=r

" Check file with shellcheck
	map <leader>s :!clear && shellcheck %<CR>

" Autoremove trailing whitespace
	autocmd BufWritePost * %s/\s\+$//e

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
	nnoremap ; :

" Quick write/quit
	nnoremap qq :q<cr>
	nnoremap ww :w<cr>
	nnoremap wq :wq<cr>
	nnoremap q1 :q!<cr>
