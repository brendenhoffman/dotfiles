# .local/share

Here you will find the plugins I have explicitly installed. They are just symlinks, so here is a list with links. You can download them via your package manager and symlink them to this dir, or git clone their git repo here.

## Zsh:
[fzf-tab](https://github.com/Aloxaf/fzf-tab)
[powerlevel10k](https://github.com/romkatv/powerlevel10k)
[zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search)
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

## Neovim:
[ale](https://github.com/dense-analysis/ale)
[syntastic](https://github.com/vim-syntastic/syntastic)
[vim-airline](https://github.com/vim-airline/vim-airline)
[vim-slime](https://github.com/jpalardy/vim-slime)
[vimwiki](https://github.com/vimwiki/vimwiki)

Currently, I host [fzf-tab-git](https://aur.archlinux.org/packages/fzf-tab-git/) and [nvim-ghost-git](https://aur.archlinux.org/packages/nvim-ghost-git/) on the AUR, so I encourage you to check it out.

Note for Arch users: installing Powerlevel10k via pacman will not install it into you /usr/zsh/plugins directory. Handle this as you please, but please note that my .zshrc will look for it in this directory.
