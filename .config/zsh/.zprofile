export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"

if [ -d "$HOME/.root/usr/bin" ] ; then
    export USERROOT="$HOME/.root"
    export PATH=$PATH:"$USERROOT/usr/bin"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$USERROOT/lib":"$USERROOT/lib64"
fi

if [ -d "$HOME/bin" ] ; then
    PATH=$PATH:"$HOME/bin"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH=$PATH:"$HOME/.local/bin"
fi

if [ -d "$HOME/.junest" ] ; then
    export PATH="$XDG_DATA_HOME/.junest/bin":$PATH
    export PATH=$PATH:"$HOME/.junest/bin_wrappers"
fi

if [ -d "$HOME/.local/share/man" ] ; then
    MANPATH=$MANPATH:"$HOME/.local/share/man"
fi

export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim -Z --noplugin"
export READER="zathura"
export ANDROID_HOME="/opt/android-sdk"
export MOZ_WEBRENDER="1"
export MANPAGER='nvim +Man! -c "set number relativenumber"'
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-r
export LESSHISTFILE="$XDG_CACHE_HOME/.lesshst"
export CARGO_HOME="$XDG_CACHE_HOME/cargo"
export GNUPGHOME="$XDG_CACHE_HOME/gnupg"
export XAUTHORITY="$XDG_CACHE_HOME/.Xauthority"
export GPG_TTY=$TTY
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx
# export XMODIFIERS=@im=fcitx
