function zed --description 'open zed (tries zeditor, zed-editor, zed, zedit)'
    for bin in zeditor zed-editor zed zedit
        if command -q $bin
            command $bin $argv
            return
        end
    end
    echo "zed: binary not found (tried: zeditor zed-editor zed zedit)" >&2
    return 1
end
