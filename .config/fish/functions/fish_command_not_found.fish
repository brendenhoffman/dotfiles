function fish_command_not_found
    echo "fish: command not found: $argv[1]" >&2
    if command -q pacman
        set -l pkgs (pacman -F -- "/usr/bin/$argv[1]" 2>/dev/null)
        if test (count $pkgs) -gt 0
            echo "$argv[1] may be found in the following packages:"
            printf '%s\n' $pkgs
        end
    end
end
