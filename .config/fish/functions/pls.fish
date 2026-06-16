function pls --description 'rerun last command with sudo'
    # $history[1] is the most recently committed command. In practice this is
    # the command typed before `pls`, but if fish has already committed `pls`
    # itself to history by the time this body runs, change [1] to [2].
    sudo $history[1]
end
