# ── editor / config ────────────────────────────────────────────────────
alias v='$EDITOR'
alias sev='sudo nvim'
alias vv='sudo nvim'
alias sudoedit='sudo nvim'
alias vimrc='nvim $XDG_CONFIG_HOME/nvim/init.lua'
alias vimrcd='cl $XDG_CONFIG_HOME/nvim'
alias fishrc='nvim ~/.config/fish/config.fish'
alias fishrcd='cl ~/.config/fish/conf.d'
alias reload='exec fish'

# ── navigation ─────────────────────────────────────────────────────────
alias cd='z'
alias cd..='cd ..'
alias cl..='cl ..'
alias cdg='cd ~/.local/git'
alias gitdir='cl ~/.local/git'
alias codedir='cd $HOME/Documents/Code'

# ── listing ────────────────────────────────────────────────────────────
alias ls='lsd -ah --group-directories-first'
alias ll='lsd -alF --group-directories-first'

# ── pager / viewer ─────────────────────────────────────────────────────
alias less='$PAGER'
alias more='$PAGER'
alias cat='bat -P'
alias man='man-remote'
alias diff='nvim -d'

# ── search / filter ────────────────────────────────────────────────────
alias grep='rg'
alias fgrep='rg -F'
alias egrep='rg'
alias find='fd -H'

# ── git ────────────────────────────────────────────────────────────────
alias g='git'
alias ga='git add .'
alias gc='git commit -s -m'
alias gp='git push'
alias gs='git status'

# ── sudo wrappers ──────────────────────────────────────────────────────
alias visudo='sudo visudo'
alias dmesg='sudo dmesg'
alias systemctl='sudo systemctl'
alias sysu='/usr/bin/systemctl --user'
alias mount='sudo mount'
alias umount='sudo umount -v'
alias fdisk='sudo fdisk'
alias cfdisk='sudo cfdisk'
alias gparted='sudo gparted'
alias blkid='sudo blkid'
alias chown='sudo chown'
alias chmod='sudo chmod'
alias dd='sudo dd status=progress'

# ── system ─────────────────────────────────────────────────────────────
alias logout='sudo pkill -u $USER'
alias shutdown='shutdown now'
alias suspend='sudo systemctl suspend'
alias errlog='journalctl -p err -e'
alias xx='xrdb ~/.Xresources'
alias rmr='rm -r'

# ── file manager ───────────────────────────────────────────────────────
alias r='vifm'
alias sr='sudo vifmrun .'

# ── misc ───────────────────────────────────────────────────────────────
alias neofetch='fastfetch'
alias gpp='g++'
alias trans='transmission-cli'
alias mocp='mocp -M $XDG_CONFIG_HOME/moc/'

# ── Arch-specific ──────────────────────────────────────────────────────
alias p='paru'
alias pp='paru -S'
alias pr='paru -Rns'
alias pu='update'
alias paclck='sudo rm /var/lib/pacman/db.lck'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# Needs fish command substitution syntax, not $()
function pro
    sudo pacman -Rns (pacman -Qtdq) $argv
end

function srcinfo
    makepkg --printsrcinfo $argv > .SRCINFO
end

# command prefix avoids recursive call into this wrapper
function printenv
    command printenv $argv | $PAGER
end
