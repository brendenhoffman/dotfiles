# bare call shuts down now; args (eg. -r, -c) pass straight through instead
# of landing after a hardcoded 'now'
function shutdown --wraps shutdown --description 'shut down now, or pass args through'
    if test (count $argv) -eq 0
        command sudo shutdown now
    else
        command sudo shutdown $argv
    end
end
