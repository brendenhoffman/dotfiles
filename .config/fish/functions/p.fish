function p --wraps yay --description 'AUR helper wrapper; bare call runs the update script instead'
    if test (count $argv) -eq 0
        update
    else
        yay $argv
    end
end
