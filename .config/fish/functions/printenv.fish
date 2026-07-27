# command prefix avoids recursive call into this wrapper
function printenv
    set -l cmd (string split ' ' -- $PAGER)
    command printenv $argv | $cmd
end
