function more
    set -l cmd (string split ' ' -- $PAGER)
    $cmd $argv
end
