export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin"

typeset -U path
[[ -n $XDG_BIN_HOME && ${path[(Ie)$XDG_BIN_HOME]} -eq 0 ]] && path+=("$XDG_BIN_HOME")
