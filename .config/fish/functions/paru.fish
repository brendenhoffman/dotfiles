function paru --wraps paru --description 'run the chosen AUR helper'
    set -l helper (_aur_helper)
    if test -z "$helper"
        echo "paru: no AUR helper installed" >&2
        return 127
    end
    command $helper $argv
end
