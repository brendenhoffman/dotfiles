export EDITOR="nvim"
export VISUAL="nvim"
export SUDO_EDITOR="nvim -Z --noplugin"

# pager
export MANPAGER='nvim +Man! -c "setlocal nonumber norelativenumber signcolumn=no statuscolumn="'

# Less + colors
export LESS=-r
export LESSHISTFILE="$XDG_CACHE_HOME/.lesshst"
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'

# Toolchain homes
export ANDROID_HOME="/opt/android-sdk"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GRADLE_USER_HOME="$XDG_DATA_HOME/gradle"
export NPM_CONFIG_USERCONFIG="$XDG_CONFIG_HOME/npm/npmrc"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export NPM_CONFIG_PREFIX="$HOME/.local"
export JAVA_TOOL_OPTIONS="-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"
export GOPATH="$XDG_DATA_HOME/go"
export GOBIN="$HOME/.local/bin"

# Crypto / desktop
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export SSH_ASKPASS='/usr/bin/ksshaskpass'
export MOZ_WEBRENDER="1"
export XAUTHORITY="$XDG_CACHE_HOME/.Xauthority"
export GTK2_RC_FILES="$HOME/.config/gtk-2.0/gtkrc"
export PULSE_COOKIE="$HOME/.config/pulse/cookie"

# TeX
export TEXMFHOME="$XDG_DATA_HOME/texmf"
export TEXMFVAR="$XDG_CACHE_HOME/texlive/texmf-var"
export TEXMFCONFIG="$XDG_CONFIG_HOME/texlive/texmf-config"

if [[ -d "$HOME/.local/share/man" ]] && command -v manpath >/dev/null; then
  export MANPATH="$HOME/.local/share/man:$(manpath -q)"
fi

