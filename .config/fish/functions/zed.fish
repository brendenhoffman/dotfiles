function zed --description 'open zed (tries zeditor, zed-editor, zed, zedit)'
    set -l bin (_zed_bin)
    if test -z "$bin"
        echo "zed: binary not found (tried: zeditor zed-editor zed zedit)" >&2
        return 1
    end
    command $bin $argv
end
