[ -d "$HOME/.root/usr/bin" ] && export USERROOT="$HOME/.root" && export PATH=$PATH:"$USERROOT/usr/bin" && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$USERROOT/lib":"$USERROOT/lib64"

[ -d "$HOME/.local/bin" ] && PATH=$PATH:"$HOME/.local/bin"

[ -d "$HOME/.junest" ] && export PATH="$HOME/.local/share/junest/bin":$PATH:"$HOME/.junest/usr/bin_wrappers"

[ -d "$HOME/.local/share/man" ] && MANPATH=$MANPATH:"$HOME/.local/share/man"

export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim -Z --noplugin"
export READER="zathura"
export ANDROID_HOME="/opt/android-sdk"
export MOZ_WEBRENDER="1"
export PAGER=$(command -v nvimpager || /usr/bin/less -R)
export MANPAGER='nvim +Man! -c "set number relativenumber"'
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-r
export GPG_TTY=$TTY
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx
# export XMODIFIERS=@im=fcitx 

