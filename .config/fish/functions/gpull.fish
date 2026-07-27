# fetch + hard-reset to origin's version of the current branch; confirms
# first since this discards local commits/changes with no way back
function gpull --description "fetch origin and hard-reset the current branch to match"
    set -l branch (git branch --show-current)
    git fetch origin
    read -l -P "Reset '$branch' to origin/$branch, discarding local changes? [y/N] " confirm
    if test "$confirm" = y -o "$confirm" = Y
        git reset --hard origin/$branch
    else
        echo "Aborted."
    end
end
