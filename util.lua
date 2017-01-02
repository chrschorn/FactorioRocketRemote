function debug_print(...)
    if not DEBUGGING then return end

    local s = ""
    for i, v in ipairs({...}) do
        s = s .. tostring(v)
    end

    game.write_file(DEBUG_FILE, s .. "\n", true)

    for _, player in pairs(game.players) do
        if player.connected then player.print("DEBUG: " .. s) end
    end
end

function set_insert(set, obj)
    -- avoid duplicates in a list (aka "set")
    for i, obj2 in pairs(set) do
        if obj2 == obj then return(false) end
    end
    table.insert(set, obj)
    return(true)
end
