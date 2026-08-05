function dots --description 'open dotfiles repo in zed, falling back to cl (cd+ls) if zed unavailable'
    if _zed_bin >/dev/null
        zed ~/.local/git/dotfiles
    else
        cl ~/.local/git/dotfiles
    end
end
