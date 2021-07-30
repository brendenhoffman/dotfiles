if [ -d "$HOME/bin" ] ; then
    PATH="$PATH:$HOME/bin"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$PATH:$HOME/.local/bin"
fi

if [ -d "$HOME/.local/share/man" ] ; then
    MANPATH="$MANPATH:$HOME/.local/share/man"
fi

export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim -Z --noplugin"
export READER="zathura"
export ANDROID_HOME="/opt/android-sdk"
export MOZ_WEBRENDER="1"
export MANPAGER='nvim +Man! -c "set number relativenumber"'
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx
# export XMODIFIERS=@im=fcitx 
