function cl --description 'z then ls'
    set -l dir $HOME
    test (count $argv) -gt 0; and set dir $argv[1]
    if test -d $dir
        z $dir && ls
    else
        echo "cl: $dir: Directory not found" >&2
        return 1
    end
end
