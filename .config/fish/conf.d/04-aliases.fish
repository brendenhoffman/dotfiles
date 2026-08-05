# ── editor / config ────────────────────────────────────────────────────
# v (functions/v.fish): opens zed, falls back to $EDITOR when unavailable
# vv (functions/vv.fish): sudoedit, falls back to sudo $EDITOR if refused
alias fishrc='zed $XDG_CONFIG_HOME/fish/config.fish'
alias fishrcd='cl $XDG_CONFIG_HOME/fish/conf.d'
alias reload='exec fish'
# aliases (functions/aliases.fish): edits this file via v (zed, falls back to $EDITOR)
# dots (functions/dots.fish): opens dotfiles repo in zed, falls back to cl

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
# less, more (functions/less.fish, functions/more.fish)
alias cat='bat -P'
alias man='man-remote'
# diff (functions/diff.fish)

# ── search / filter ────────────────────────────────────────────────────
alias grep='rg'
alias fgrep='rg -F'
alias egrep='rg'
alias find='fd -H'

# ── git ────────────────────────────────────────────────────────────────
alias g='git'
alias ga='git add -A'
alias gc='git commit -s -m'
alias gp='git push'
alias gs='git status'
# gpull (functions/gpull.fish)

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
# shutdown (functions/shutdown.fish)
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
# 'p' is a function (see functions/p.fish): bare 'p' runs the update script,
# 'p <args>' passes through to the yay/paru wrapper.
alias pp='yay -S'
alias pr='yay -Rns'
alias pu='update'
alias paclck='sudo rm /var/lib/pacman/db.lck'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
# pro, srcinfo, printenv (functions/pro.fish, functions/srcinfo.fish, functions/printenv.fish)
