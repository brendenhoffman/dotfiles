function v --description 'open zed, falling back to $EDITOR on headless boxes'
    if _zed_bin >/dev/null
        zed $argv
    else
        $EDITOR $argv
    end
end
