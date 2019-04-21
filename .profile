# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

export EDITOR="nvim"
export SUDO_EDITOR="nvim -Z"
export TERMINAL="st"
export READER="zathura"
export PATH="$PATH:/usr/sbin:$(du $HOME/.scripts/ | cut -f2 | tr '\n' ':')"
export XMODIFIERS=@im=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export ANDROID_HOME="/opt/android-sdk"

if [[ ! $DISPLAY &&XDG_VTNR -eq 1 ]]; then
	exec startx
fi
