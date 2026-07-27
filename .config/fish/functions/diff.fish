function diff --wraps diff
    if command -q zeditor; or command -q zed-editor; or command -q zed; or command -q zedit
        zed -diff $argv
    else
        delta $argv
    end
end
