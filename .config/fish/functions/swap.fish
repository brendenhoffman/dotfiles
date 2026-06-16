function swap --description 'swap two files'
    if test (count $argv) -ne 2
        echo "swap: need exactly 2 arguments" >&2
        return 1
    end
    set -l a $argv[1]
    set -l b $argv[2]
    mv -- $a $a._tmp && mv -- $b $a && mv -- $a._tmp $b
end
