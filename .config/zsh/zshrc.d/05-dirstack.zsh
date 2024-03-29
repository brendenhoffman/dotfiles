autoload -Uz add-zsh-hook

DIRSTACKFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/dirs"
[[ -f "$DIRSTACKFILE" ]] && (( ${#dirstack} == 0 )) && dirstack=("${(@f)"$(< "$DIRSTACKFILE")"}") && [[ -d "${dirstack[1]}" ]] && cd -- "${dirstack[1]}"

chpwd_dirstack() {
    print -l -- "$PWD" "${(u)dirstack[@]}" > "$DIRSTACKFILE"
}
add-zsh-hook -Uz chpwd chpwd_dirstack

DIRSTACKSIZE='30'

setopt AUTO_PUSHD PUSHD_SILENT PUSHD_TO_HOME

## Remove duplicate entries
setopt PUSHD_IGNORE_DUPS

## This reverts the +/- operators.
setopt PUSHD_MINUS
