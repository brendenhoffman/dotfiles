# GPG needs the real tty, not $TTY which isn't set in fish
set -gx GPG_TTY (tty)

# Toolchain homes — mirror what .zprofile exports for zsh sessions.
# (XDG base dirs themselves come from environment.d/10-xdg.conf via PAM.)
set -gx CARGO_HOME  $XDG_DATA_HOME/cargo
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOBIN  $HOME/.local/bin

set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
set -gx NPM_CONFIG_CACHE      $XDG_CACHE_HOME/npm
set -gx NPM_CONFIG_PREFIX     $HOME/.local

set -gx ANDROID_HOME   /opt/android-sdk
set -gx ANDROID_USER_HOME $XDG_DATA_HOME/android
set -gx GNUPGHOME      $XDG_DATA_HOME/gnupg
set -gx GRADLE_USER_HOME $XDG_DATA_HOME/gradle
set -gx WINEPREFIX     $XDG_DATA_HOME/wine
set -gx FG_HOME        $XDG_DATA_HOME/flightgear
set -gx DOTNET_BUNDLE_EXTRACT_BASE_DIR $XDG_CACHE_HOME/dotnet-bundle-extract
set -gx WGETRC         $XDG_CONFIG_HOME/wget/wgetrc

set -gx TEXMFHOME   $XDG_DATA_HOME/texmf
set -gx TEXMFVAR    $XDG_CACHE_HOME/texlive/texmf-var
set -gx TEXMFCONFIG $XDG_CONFIG_HOME/texlive/texmf-config

set -gx JAVA_TOOL_OPTIONS "-Djava.util.prefs.userRoot=$XDG_CONFIG_HOME/java"

set -gx LESSHISTFILE $XDG_CACHE_HOME/.lesshst

set -gx MOZ_WEBRENDER    1
set -gx XAUTHORITY       $XDG_CACHE_HOME/.Xauthority
set -gx GTK2_RC_FILES    $HOME/.config/gtk-2.0/gtkrc
set -gx PULSE_COOKIE     $HOME/.config/pulse/cookie
set -gx SSH_ASKPASS      /usr/bin/ksshaskpass
set -gx READER           zathura
set -gx EDITOR micro
set -gx VISUAL micro
set -gx SUDO_EDITOR micro
set -gx PAGER 'bat --paging=always'
set -gx BAT_PAGER 'less -R --search-options=W'
set -gx MANPAGER manpager
set -gx MANROFFOPT '-c'
set -gx DIFFPROG 'delta'
