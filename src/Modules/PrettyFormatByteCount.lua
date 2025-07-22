local NAMES = {"KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"}

return function(bytes: number)
    for i = 1, #NAMES do
        local min = bytes / 1024 ^ i
        local max = bytes / 1024 ^ (i + 1)
        if max < 1 or i == #NAMES then
            return "~" .. string.format("%.2f", min) .. NAMES[i]
        end
    end
    error("Can't happen")
end
