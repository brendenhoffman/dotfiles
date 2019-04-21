# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

shopt -s autocd #cd by typing name

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=50000
HISTFILESIZE=
HISTCONTROL=ignoreboth # don't put duplicate lines or lines starting with space in the history.
LESSHISTFILE=/dev/null
shopt -s histappend # append to the history file, don't overwrite it

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set Bash promt, capitalize if root.
if [ "$EUID" -ne 0 ]
then export PS1="/\u|\h/ \W "
        else export PS1="/ROOT|ARARARAGI/ \W "
fi

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f /usr/share/doc/pkgfile/command-not-found.bash ]; then
	. /usr/share/doc/pkgfile/command-not-found.bash
fi

if [ -f /etc/profile.d/autojump.bash ]; then
	. /etc/profile.d/autojump.bash
fi
