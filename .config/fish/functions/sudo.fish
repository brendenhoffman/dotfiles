function sudo --wraps sudo
    if test (count $argv) -gt 0; and functions -q -- $argv[1]; and not set -q _SUDO_FISH_EXPAND
        set -l fn_def (functions -- $argv[1])
        set -l pattern (string join '' -- "--description 'alias " $argv[1] "[ =]([^']+)'")
        set -l alias_target (string match -rg -- $pattern $fn_def)
        if test -n "$alias_target"
            # Simple alias: run the underlying binary directly — no fish subprocess needed
            command sudo -E (string split ' ' $alias_target) $argv[2..-1]
        else
            # Complex function: write to temp file — (string join \n) splits back into a list
            # when captured with (), so fish -c $script only ever sees the first line
            set -l tmp (mktemp /tmp/sudo_fish.XXXXXX)
            printf '%s\n' 'set -gx _SUDO_FISH_EXPAND 1' "set -gx PATH "(string join ' ' $PATH) $fn_def (string join ' ' -- (string escape -- $argv)) > $tmp
            command sudo -E fish $tmp
            set -l ret $status
            command rm -f $tmp
            return $ret
        end
    else
        command sudo $argv
    end
end
