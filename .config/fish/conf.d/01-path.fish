# fish_add_path is idempotent: adds entries to $fish_user_paths only if absent.
# Prepend so our local installs shadow system copies.
fish_add_path $HOME/.local/bin
fish_add_path $CARGO_HOME/bin
fish_add_path $GOBIN
