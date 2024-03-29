# swap function
function swap() { mv $1 $1._tmp && mv $2 $1 && mv $1._tmp $2; }

#cd and ls function
cl() {
    local dir="$1"
    local dir="${dir:=$HOME}"
    if [[ -d "$dir" ]]; then
        cd "$dir" >/dev/null; ls
    else
        echo "bash: cl: $dir: Directory not found"
    fi
}

#Universal extract function
extract() {
    local c e i

    (($#)) || return

    for i; do
        c=''
        e=1

        [[ ! -r $i ]] && echo "$0: file is unreadable: \`$i'" >&2 && continue

        case $i in
            *.t@(gz|lz|xz|b@(2|z?(2))|a@(z|r?(.@(Z|bz?(2)|gz|lzma|xz)))))
                   c=(bsdtar xvf);;
            *.7z)  c=(7z x);;
            *.Z)   c=(uncompress);;
            *.bz2) c=(pbunzip2);;
            *.exe) c=(cabextract);;
            *.gz)  c=(unpigz);;
            *.rar) c=(unrar x);;
            *.xz)  c=(unxz);;
            *.zip) c=(unzip);;
            *.zst) c=(unzstd);;
            *)     echo "$0: unrecognized file extension: \`$i'" >&2
                   continue;;
        esac

        command "${c[@]}" "$i"
        ((e = e || $?))
    done
    return "$e"
}

# pacman "command not found" handler
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=(${(f)"$(pacman -F --machinereadable -- "$1")"})
    (( ${#entries[@]} )) && printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}"
        do
            # (repo package version file)
            local fields=(${(0)entry})
            [[ "$pkg" != "${fields[2]}" ]] && printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
}

