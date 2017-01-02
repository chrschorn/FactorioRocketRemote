local function init_player(player)
    if global.initialized ~= 1 then
        global.initialized = 1
        player.print(player.name)
        player.gui.left.add{type="label", name="greeting", caption="This is a test... Hello World!"} 
    end
end

local function on_init()
    for _, player in pairs(game.players) do
        init_player(player)
    end
end

script.on_init(on_init)


local function on_player_created(event)
	-- called at player creation
	local player = game.players[event.player_index]
	init_player(player)
end

script.on_event(defines.events.on_player_created, on_player_created )


--------------------------------------------------------------------------------------
local function on_player_joined_game(event)
	-- called in SP(once) and MP(every connect), eventually after on_player_created
	local player = game.players[event.player_index]
	init_player(player)
end

script.on_event(defines.events.on_player_joined_game, on_player_joined_game )
