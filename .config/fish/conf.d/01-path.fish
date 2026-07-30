if test (id -u) -eq 0
    # Never trust user-writable bin dirs for a root shell. $fish_user_paths
    # is a universal variable fish merges into $PATH on every startup
    # regardless of whether fish_add_path runs again (e.g. sudo.fish's
    # temp-script mechanism spawns a real fish process, which still sources
    # this file since $HOME is preserved across sudo) — so it has to be
    # stripped out directly, not just skipped. Root falls back to the
    # root-owned /usr/local/bin copies install.sh provisions instead.
    set -l strip $HOME/.local/bin $CARGO_HOME/bin $GOBIN
    set -l kept
    for p in $PATH
        contains -- $p $strip; or set -a kept $p
    end
    set -gx PATH $kept
    return
end

# --move forces these to the front even if environment.d/20-path.conf
# already appended them to $PATH (PAM runs before fish does) — without it,
# fish_add_path no-ops on dirs already present and leaves them wherever
# PAM put them, letting system copies shadow our local installs instead
# of the other way around.
fish_add_path --move $HOME/.local/bin
fish_add_path --move $CARGO_HOME/bin
fish_add_path --move $GOBIN
