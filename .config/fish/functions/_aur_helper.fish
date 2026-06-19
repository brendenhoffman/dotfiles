function _aur_helper --description 'pick yay or paru based on version/availability'
    set -l have_yay (command -q yay; and echo 1)
    set -l have_paru (command -q paru; and echo 1)

    if test -z "$have_yay$have_paru"
        return 1
    else if test -z "$have_paru"
        echo yay
    else if test -z "$have_yay"
        echo paru
    else
        set -l yay_ver (command yay --version | string match -rg 'v(\d+)\.')
        if test -n "$yay_ver"; and test "$yay_ver" -ge 13
            echo yay
        else if not test -f "$XDG_CONFIG_HOME/paru/paru.conf"
            echo yay
        else
            echo paru
        end
    end
end
