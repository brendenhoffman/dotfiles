export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
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

export SSH_ASKPASS='/usr/bin/ksshaskpass'

export GPG_TTY=$TTY
