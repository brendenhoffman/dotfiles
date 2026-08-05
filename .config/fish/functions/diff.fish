function diff --wraps diff
    if _zed_bin >/dev/null
        zed -diff $argv
    else
        delta $argv
    end
end
