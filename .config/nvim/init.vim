let mapleader=" "
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

" Plugins
	let g:slime_target = "tmux"
	let g:slime_paste_file = "$HOME/.slime_paste"
	let g:slime_default_config = {"socket_name": get(split($TMUX, ","), 0), "target_pane": ":.1"}

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
	noremap ; :

" Quick write/quit
	noremap qq :q<cr>
	noremap ww :w<cr>
	noremap wq :wq<cr>
	noremap q1 :q!<cr>

" Reload config
    nnoremap <leader>sv :source ~/.config/nvim/init.vim<CR>

" Shut up nvim-ghost
    let g:nvim_ghost_super_quiet = 1
