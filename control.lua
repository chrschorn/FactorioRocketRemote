DEBUGGING = false
DEBUG_FILE = "rocketremote_debug.txt"

require("util")

local GUI_NAME = "rocket_remote"
local GUI_POS = "left"

local UPDATE_INTERVAL = 5 -- seconds


-------------------------------------------------------------------------------

local function init_globals()
    if global.silos ~= nil then return end

    global.silos = {}
    global.autolaunch = false
    global.rocket_count = -1
end


local function gui_root_obj(player)
    -- helper function to access the gui root element
    return(player.gui[GUI_POS][GUI_NAME])
end


local function remove_gui(player)
    -- removes the gui of this mod
    local gui = gui_root_obj(player)
    if gui ~= nil then 
        gui.destroy()
    end
end


local function remove_default_rocket_score(player)
    default_rocket_score_gui = player.gui.left.rocket_score

    if default_rocket_score_gui == nil then return(false) end

    if global.rocket_count == -1 then
        local total = tonumber(default_rocket_score_gui.rocket_count.caption)
        if total == nil then
            global.rocket_count = 0
        else
            global.rocket_count = total
        end
    end

    default_rocket_score_gui.destroy()
    return(true)
end


local function silo_counts()
    -- returns total silo count and amount of silos that are ready to launch
    local silo_count = 0
    local silo_ready = 0
    for _, silo in pairs(global.silos) do
        if silo.valid then
            silo_count = silo_count + 1
            if silo.get_item_count("satellite") > 0 then
                silo_ready = silo_ready + 1
            end
        end
    end

    return silo_count, silo_ready
end


local function init_gui(player)
    -- initializes the gui, if there are any rocket silos present
    debug_print("init_gui")

    remove_default_rocket_score(player)

    if next(global.silos) ~= nil then  -- if there even are any silos
        local gui_root = gui_root_obj(player)
        local silo_count, silo_ready = silo_counts()

        remove_gui(player)

        local gui_root = player.gui[GUI_POS].add{type="frame", name=GUI_NAME, direction="vertical", style="rr_frame_style"} 
        gui_root.add{type="label",
                     name="rr_title",
                     caption=string.format("Rocket silos ready: %d/%d", silo_ready, silo_count),
                     style="rr_label_style_bold"}
        gui_root.add{type="label", name="rr_rocketcount", caption="Rockets sent: " .. global.rocket_count, style="rr_label_style"}
        local gui2 = gui_root.add{type="table", name="rr_button_table", colspan=2}
        gui2.add{type="checkbox", name="rr_autolaunch_cb", caption="Autolaunch", state=global.autolaunch, style="rr_checkbox_style"}

        if not global.autolaunch then
            gui2.add{type="button", name="rr_launch", caption="LAUNCH", style="rr_button_style"}
        end
    end
end


local function init_player(player)
    -- initializes player data and gui, call on connect or on_init
    debug_print("init_player: " .. player.name)

    local gui_root = gui_root_obj(player)
    if gui_root ~= nil then gui_root.destroy() end

    init_gui(player)
end


local function find_silos()
    -- finds all silos that may have been present before this mod
    for _, surface in pairs(game.surfaces) do
        for _, silo in pairs(surface.find_entities_filtered({type="rocket-silo"})) do
            set_insert(global.silos, silo)
        end
    end
end


local function launch_rockets()
    -- launches all rocket silos that have a satellite
    debug_print(global.silos)

    if global.silos == nil then global.silos = {} end

    local silos_launched = 0

    for k, silo in pairs(global.silos) do
        if silo.valid then
            if silo.get_item_count("satellite") > 0 then
                silo.launch_rocket()
                silos_launched = silos_launched + 1
            end
        end
    end

    if silos_launched == 0 then return end

    for _, player in pairs(game.players) do
        player.print(string.format("Launched %d rocket%s!", silos_launched, silos_launched > 1 and "s" or ""))
    end

    global.rocket_count = global.rocket_count + silos_launched  -- instantly update count
end


local function update_gui()
    -- updates the gui based on silo and silo-ready counts
    local silos, silos_ready = silo_counts()

    for _, player in pairs(game.players) do
        local gui_root = gui_root_obj(player)
        if gui_root ~= nil then
            gui_root["rr_title"].caption = string.format("Rocket silos ready: %d/%d", silos_ready, silos)
            gui_root["rr_rocketcount"].caption = "Rockets sent: " .. global.rocket_count

            if global.autolaunch and gui_root["rr_launch"] ~= nil then
                gui_root["rr_launch"].destroy()
            end
        end

        if next(global.silos) == nil then  -- no rocket silos
            remove_gui(player)
        elseif gui_root_obj(player) == nil then  -- gui not built yet
            init_gui(player)
        end
    end
end


local function update()
    -- updates silo ready count and initializes or destroys gui based on
    -- gui count. launches rocket if autolaunch is activated
    if global.silos == nil then global.silos = {} end

    update_gui()

    if global.autolaunch then
        launch_rockets()
        update_gui()
    end
end


-------------------------------------------------------------------------------
-- Below: all functions that get registered with the Factorio API
-------------------------------------------------------------------------------


local function on_tick()
    -- updates every few ticks (e.g. 300 ticks = ~5 seconds)
    if game.tick % (UPDATE_INTERVAL * 60) ~= 0 then return end

    update()
end
script.on_event(defines.events.on_tick, on_tick)


local function built_entity(event)
    -- update silo table if a new silo was built
    if global.silos == nil then global.silos = {} end

    if next(global.silos) == nil then  -- first silo, enable gui
        for _, player in pairs(game.players) do
            init_gui(player)
        end
    end

    if event.created_entity.name == "rocket-silo" then
        set_insert(global.silos, event.created_entity)
    end
end
script.on_event(defines.events.on_built_entity, built_entity)
script.on_event(defines.events.on_robot_built_entity, built_entity)


local function on_rocket_launched(event)
    local force = event.rocket.force
    local deleted_default_gui = false

    for _, player in pairs(force.players) do
        if player.connected then
            deleted_default_gui = remove_default_rocket_score(player)
        end
    end

    if not deleted_default_gui then
        global.rocket_count = global.rocket_count + 1
    end

    update_gui()
end
script.on_event(defines.events.on_rocket_launched, on_rocket_launched)


local function on_init()
    -- is only ever called once per savegame!
    for _, player in pairs(game.players) do
        debug_print(player.name .. " connected")
        init_globals()
        init_player(player)
        find_silos()
    end
end
script.on_init(on_init)


local function on_player_created(event)
	-- called at player creation
	local player = game.players[event.player_index]
    debug_print(player.name .. " connected")
    init_globals()
	init_player(player)
end
script.on_event(defines.events.on_player_created, on_player_created )


local function on_player_joined_game(event)
	-- called in SP(once) and MP(every connect), eventually after on_player_created
	local player = game.players[event.player_index]
    debug_print(player.name .. " connected")
    init_globals()
	init_player(player)
end
script.on_event(defines.events.on_player_joined_game, on_player_joined_game )


local function on_configuration_changed(data)
	-- detect any mod or game version change
	if data.mod_changes ~= nil then
		local changes = data.mod_changes[debug_mod_name]
		if changes ~= nil then
			-- migrations
			for _, player in pairs(game.players) do
                init_globals()
                init_player(player)
			end
        end
	end
end
script.on_configuration_changed(on_configuration_changed)


local function on_gui_click(event)
    -- handles gui events
    local player = game.players[event.player_index]
    local event_name = event.element.name

    if event_name == "rr_launch" then
        launch_rockets()
        update()
    elseif event_name == "rr_autolaunch_cb" then
        global.autolaunch = gui_root_obj(player)["rr_button_table"]["rr_autolaunch_cb"].state
        update()
        init_gui(player)
    end
end
script.on_event(defines.events.on_gui_click, on_gui_click)

