function fish_command_not_found
    echo "fish: command not found: $argv[1]" >&2

    # On Arch, suggest packages via pacman -F (requires pacman-contrib/pkgfile sync)
    if command -q pacman
        set -l entries (pacman -F --machinereadable -- "/usr/bin/$argv[1]" 2>/dev/null)
        if test (count $entries) -gt 0
            set_color --bold
            printf '%s may be found in the following packages:\n' $argv[1]
            set_color normal
            set -l prev_pkg ''
            for entry in $entries
                # machinereadable format: repo\0package\0version\0file
                set -l fields (string split \0 $entry)
                if test "$prev_pkg" != "$fields[2]"
                    set_color magenta
                    printf '%s/' $fields[1]
                    set_color --bold
                    printf '%s ' $fields[2]
                    set_color green
                    printf '%s\n' $fields[3]
                    set_color normal
                    set prev_pkg $fields[2]
                end
                printf '    /%s\n' $fields[4]
            end
        end
    end
end
