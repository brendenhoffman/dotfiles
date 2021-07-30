# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

HISTFILE=~/.config/zsh/zhistory
HISTSIZE=100000
SAVEHIST=4096

WORDCHARS=${WORDCHARS//\/[&.;]}                       # Don't consider certain characters part of the word

# use zshrc.d directory for config
for _f in "$ZDOTDIR"/zshrc.d/*.{sh,zsh}(.N); do
  # ignore files that begin with a tilde
  case $_f:t in ~*) continue;; esac
  source "$_f"
done
unset _f

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f $ZDOTDIR/.p10k.zsh ]] || source $ZDOTDIR/.p10k.zsh

# Clear propmt on startup. Fixes bug with p10k and Krohnkite.
sleep 0.004&&clear
