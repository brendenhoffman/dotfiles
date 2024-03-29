# Enable Powerlevel10k instant prompt.
[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && . "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/" 2>/dev/null

HISTFILE=~/.cache/zsh/zhistory
HISTSIZE=100000
SAVEHIST=4096

WORDCHARS=${WORDCHARS//\/[&.;]}                       # Don't consider certain characters part of the word

# use zshrc.d directory for config
for _f in "$ZDOTDIR"/zshrc.d/*.{sh,zsh}(.N); do
  # ignore files that begin with a tilde
  case $_f:t in ~*) continue;; esac
  . "$_f"
done
unset _f

#Only for Steam Deck
[[ "$USER" == "deck" ]] && for _f in "$ZDOTDIR"/deck.d/*.{sh,zsh}(.N); do
case $_f:t in ~*) continue;; esac
. "$_f"
done
unset _f

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[ -f $ZDOTDIR/.p10k.zsh ] && . $ZDOTDIR/.p10k.zsh

