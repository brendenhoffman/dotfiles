shopt -s expand_aliases

# swap command
function swap() { mv $1 $1._tmp && mv $2 $1 && mv $1._tmp $2; }

# enable color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls -hN --color=auto --group-directories-first'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias r='vu'
alias sr='sudo vifm'
alias sev='sudoedit'
alias vv='sudo nvim'
alias v=$EDITOR
alias g='git'
alias bashconfig='v ~/.bashrc'
alias hostsoff='sudo mv /etc/hosts /etc/hosts.off'
alias hostson='sudo mv /etc/hosts.off /etc/hosts'
alias dd='sudo dd status=progress'
alias p='sudo pacman'
alias pu='sudo pacman -Syyu'
alias pro='sudo pacman -Rns $(pacman -Qtdq)'
alias visudo='sudo -E visudo'
alias logout='sudo pkill -KILL -u ren'
alias shutdown='sudo shutdown'
alias reboot='sudo reboot'
alias suspend='sudo pm-suspend'
alias mount='sudo mount'
alias umount='sudo umount -v'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias fdisk='sudo fdisk'
alias cfdisk='sudo cfdisk'
alias gparted='sudo gparted'
alias aliases='nvim ~/.bash_aliases'
alias blkid='sudo blkid'
alias chown='sudo chown'
alias chmod='sudo chmod'
alias xx='xrdb ~/.Xresources'
