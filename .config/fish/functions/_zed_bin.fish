function _zed_bin --description 'echo the first available zed binary name, or fail if none installed'
    for bin in zeditor zed-editor zed zedit
        if command -q $bin
            echo $bin
            return 0
        end
    end
    return 1
end
