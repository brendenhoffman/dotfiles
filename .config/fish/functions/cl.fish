function cl --description 'cd then ls'
    set -l dir $HOME
    if test (count $argv) -gt 0
        set dir $argv[1]
    end
    if test -d $dir
        cd $dir && ls
    else
        echo "cl: $dir: Directory not found" >&2
        return 1
    end
end
