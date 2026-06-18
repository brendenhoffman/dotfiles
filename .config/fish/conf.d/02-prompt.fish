set fish_greeting
if command -q starship
    starship init fish | source
end
