# Needs fish command substitution syntax, not $()
function pro
    sudo pacman -Rns (pacman -Qtdq) $argv
end
