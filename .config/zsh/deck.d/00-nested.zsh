#Only do this if it is nested
if [ "$SHLVL" -ge 4 ] && [ "$DESKTOP_SESSION" = "gamescope-wayland" ]; then
    [ -d "$HOME/.root/usr/bin" ] && export USERROOT="$HOME/.root" && export PATH=$PATH:"$USERROOT/usr/bin" && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"$USERROOT/lib":"$USERROOT/lib64"

    [ -d "$HOME/.local/bin" ] && PATH=$PATH:"$HOME/.local/bin"

    [ -d "$HOME/.local/share/man" ] && export MANPATH=$MANPATH:"$HOME/.local/share/man"

    #Just to keep child processes from adding on
    # to modify use `unset -f`
    readonly PATH
    readonly LD_LIBRARY_PATH
    readonly MANPATH

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
    export GPG_TTY=$TTY
    export _NESTED="1"
fi
