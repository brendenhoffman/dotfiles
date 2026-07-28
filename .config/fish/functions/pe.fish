function pe --wraps yay --description 'clean-build and edit PKGBUILDs before installing'
    set -l helper (_aur_helper)
    if test -z "$helper"
        echo "pe: no AUR helper installed" >&2
        return 127
    end
    if test "$helper" = yay
        command yay --cleanmenu --answerclean=all --editmenu --answeredit=all $argv
    else
        command paru --cleanafter --rebuild=all --review $argv
    end
end
