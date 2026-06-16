function extract --description 'extract archives'
    if test (count $argv) -eq 0
        echo "extract: provide at least one archive" >&2
        return 1
    end

    set -l e 0
    for f in $argv
        if not test -r $f
            echo "extract: unreadable: $f" >&2
            set e 1
            continue
        end

        switch $f
            case '*.tar.gz' '*.tgz'
                tar xvzf $f
            case '*.tar.bz2' '*.tbz' '*.tbz2'
                tar xvjf $f
            case '*.tar.xz' '*.txz'
                tar xvJf $f
            case '*.tar.zst'
                tar --zstd -xvf $f
            case '*.tar'
                tar xvf $f
            case '*.7z'
                7z x $f
            case '*.Z'
                uncompress $f
            case '*.bz2'
                pbunzip2 $f
            case '*.exe'
                cabextract $f
            case '*.gz'
                unpigz $f
            case '*.rar'
                unrar x $f
            case '*.xz'
                unxz $f
            case '*.zip'
                unzip $f
            case '*.zst'
                unzstd $f
            case '*'
                echo "extract: unrecognized extension: $f" >&2
                set e 1
        end
    end
    return $e
end
