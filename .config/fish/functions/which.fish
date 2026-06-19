function which --wraps which --description 'show alias/function definition and binary location'
    for cmd in $argv
        if functions -q -- $cmd
            set -l fn_def (functions -- $cmd)
            # alias-created functions have description "alias name cmd..." — use that, not body parsing
            set -l pattern (string join '' -- "--description 'alias " $cmd "[ =]([^']+)'")
            set -l alias_target (string match -rg -- $pattern $fn_def)
            if test -n "$alias_target"
                echo "$cmd: aliased to $alias_target"
            else
                echo "$cmd is a fish function:"
                printf '%s\n' $fn_def | string match -rv '^\s*#'
            end
        end

        set -l bin (command --search -- $cmd 2>/dev/null)
        if test -n "$bin"
            if test -L "$bin"
                echo "$cmd is $bin symlinked to "(readlink -f -- $bin)
            else
                echo "$cmd is $bin"
            end
        end

        contains -- $cmd (builtin --names); and echo "$cmd is a fish builtin"

        if not functions -q -- $cmd; and test -z "$bin"; and not contains -- $cmd (builtin --names)
            echo "which: $cmd: not found" >&2
        end
    end
end
