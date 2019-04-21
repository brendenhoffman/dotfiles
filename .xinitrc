#!/bin/sh

userresources=$HOME/.Xresources

if [ -f "$userresources" ]; then
	xrdb -merge "$userresources"
fi

[[-f ~/.Xresources ]] && -merge -I$HOME ~/.Xresources

exec i3
