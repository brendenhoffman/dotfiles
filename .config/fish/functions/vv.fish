function vv --description 'sudoedit, falling back to sudo $EDITOR if sudoedit refuses (e.g. writable-dir check)'
    sudoedit $argv; or sudo $EDITOR $argv
end
