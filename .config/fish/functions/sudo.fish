function sudo --wraps sudo
    if test (count $argv) -gt 0; and functions -q -- $argv[1]; and not set -q _SUDO_FISH_EXPAND
        set -l fn_def (functions -- $argv[1])
        set -l pattern (string join '' -- "--description 'alias " $argv[1] "[ =]([^']+)'")
        set -l alias_target (string match -rg -- $pattern $fn_def)
        if test -n "$alias_target"
            # Simple alias: run the underlying binary directly — no fish subprocess needed.
            # Bare name, no absolute-path override: secure_path (if set) is the authority
            # on what root can run, same as any other sudo'd command.
            command sudo -E (string split ' ' $alias_target) $argv[2..-1]
        else
            # Complex function: write to temp file — (string join \n) splits back into a list
            # when captured with (), so fish -c $script only ever sees the first line.
            # No explicit PATH injection: let the spawned root fish process inherit
            # whatever sudo's real policy gives it (see 01-path.fish for why that's not
            # automatically undone by fish's own startup).
            set -l tmp (mktemp /tmp/sudo_fish.XXXXXX)
            printf '%s\n' 'set -gx _SUDO_FISH_EXPAND 1' $fn_def (string join ' ' -- (string escape -- $argv)) > $tmp
            command sudo -E fish $tmp
            set -l ret $status
            command rm -f $tmp
            return $ret
        end
    else
        command sudo $argv
    end
end
