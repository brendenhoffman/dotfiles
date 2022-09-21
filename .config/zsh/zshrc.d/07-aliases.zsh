alias aliases='nvim $ZDOTDIR/zshrc.d/07-aliases.zsh'
alias zhist='cat $XDG_CACHE_HOME/zsh/zhistory'
alias zshrc='nvim $ZDOTDIR/.zshrc'
alias reload='source $ZDOTDIR/.zshrc'
alias zshrcd='cl $ZDOTDIR/zshrc.d'
alias vimrc='nvim $XDG_CONFIG_HOME/nvim/init.vim'
alias sev='sudo nvim'
alias vv='sudo nvim'
alias sudoedit='sudo nvim'
alias v=$EDITOR
alias g='git'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gs='git status'
alias hostsoff='sudo mv /etc/hosts /etc/hosts.off'
alias hostson='sudo mv /etc/hosts.off /etc/hosts'
alias dd='sudo dd status=progress'
alias p='yay'
alias pp='yay -S'
alias pr='yay -Rns'
alias pu='yay -Syyu'
alias pro='sudo pacman -Rns $(pacman -Qtdq)'
alias visudo='sudo visudo'
alias logout='sudo pkill -u $USER'
alias shutdown='shutdown now'
alias suspend='sudo systemctl suspend'
alias mount='sudo mount'
alias umount='sudo umount -v'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias ls='ls -ahN --color=auto --group-directories-first'
alias ll='ls -alF'
alias fdisk='sudo fdisk'
alias cfdisk='sudo cfdisk'
alias gparted='sudo gparted'
alias blkid='sudo blkid'
alias chown='sudo chown'
alias chmod='sudo chmod'
alias xx='xrdb ~/.Xresources'
alias pls='sudo $(fc -ln -1)'
alias sudo='sudo '
alias printenv='printenv | less'
alias systemctl='sudo systemctl'
alias paclck='sudo rm /var/lib/pacman/db.lck'
alias diff='nvim -d'
alias trans='transmission-cli'
alias errlog='journalctl -p err -e'
alias r='vifm'
alias sr='sudo vifmrun .'
alias cd..='cd ..'
alias cl..='cl ..'
alias cdg='cd ~/.local/git'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias mocp='mocp -M $XDG_CONFIG_HOME/moc/'
alias srcinfo='makepkg --printsrcinfo > .SRCINFO'
