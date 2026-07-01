# ── editor / config ────────────────────────────────────────────────────
alias v='zed'
alias vv='sudoedit'
alias fishrc='zed $XDG_CONFIG_HOME/fish/config.fish'
alias fishrcd='cl $XDG_CONFIG_HOME/fish/conf.d'
alias reload='exec fish'
alias aliases='zed $XDG_CONFIG_HOME/fish/conf.d/04-aliases.fish'
alias dots='zed ~/local/git/dotfiles'

# ── navigation ─────────────────────────────────────────────────────────
alias cd='z'
alias cd..='cd ..'
alias cl..='cl ..'
alias cdg='cl ~/.local/git'
alias gitdir='cl ~/.local/git'
alias codedir='cl $HOME/Documents/Code'

# ── listing ────────────────────────────────────────────────────────────
alias ls='lsd -ah --group-directories-first'
alias ll='lsd -alF --group-directories-first'

# ── pager / viewer ─────────────────────────────────────────────────────
function less
    set -l cmd (string split ' ' -- $PAGER)
    $cmd $argv
end

function more
    set -l cmd (string split ' ' -- $PAGER)
    $cmd $argv
end

alias cat='bat -P'
alias man='man-remote'

function diff --wraps diff
    if command -q zeditor; or command -q zed-editor; or command -q zed; or command -q zedit
        zed -diff $argv
    else
        delta $argv
    end
end

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
alias gpull='git fetch origin && git reset --hard origin/(git branch --show-current)'

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
alias rmr='rm -r'

# ── misc ───────────────────────────────────────────────────────────────
alias neofetch='fastfetch'
alias gpp='g++'
alias trans='transmission-cli'
alias mocp='mocp -M $XDG_CONFIG_HOME/moc/'
alias updatedots='bash ~/.local/git/dotfiles/install.sh'

# ── Arch-specific ──────────────────────────────────────────────────────
alias p='yay'
alias pp='yay -S'
alias pr='yay -Rns'
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
    set -l cmd (string split ' ' -- $PAGER)
    command printenv $argv | $cmd
end
