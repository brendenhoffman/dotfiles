function yay --wraps yay --description 'run the chosen AUR helper'
    set -l helper (_aur_helper)
    if test -z "$helper"
        echo "yay: no AUR helper installed" >&2
        return 127
    end
    command $helper $argv
end
