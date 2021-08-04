bed_lives = {}

bed_lives.max_bed_lives = 6

local hud_ids_by_player_name = {}



function bed_lives.set_lives(player, lives)
    player:get_meta():set_string("bed_lives:lives", tostring(lives))
	player:hud_change(
		hud_ids_by_player_name[player:get_player_name()],
		"number",
		math.min(bed_lives.max_bed_lives, lives)
	)
end

function bed_lives.get_lives(player)
    return tonumber(player:get_meta():get_string("bed_lives:lives"))
end


minetest.register_on_joinplayer(function(player)
	local lives = bed_lives.get_lives(player) or bed_lives.max_bed_lives
    player:get_meta():set_string("bed_lives:lives", tostring(lives))
	local id = player:hud_add({
		name = "bed_lives",
		hud_elem_type = "statbar",
		position = {x = 0.5, y = 1},
		size = {x = 24, y = 24},
		text = "beds_bed.png",
		number = lives,
		-- text2 = "beds_bed.png",
		-- item = bed_lives.visual_max,
		alignment = {x = -1, y = -1},
		offset = {x = -266, y = -110},
		-- max = 0,
	})
	hud_ids_by_player_name[player:get_player_name()] = id
end)

minetest.register_on_respawnplayer(function(player)
    local old = bed_lives.get_lives(player)

    local lives = old - 2

    if lives < 0 then
        local pos = player:get_pos()
        local node = minetest.get_node(pos)
        if minetest.get_item_group(node.name, "bed") > 0 then
            minetest.dig_node(pos)
            local player_name = player:get_player_name()
            minetest.chat_send_player(player_name, "You lost you'r bed at "..math.floor(pos.x)..","..math.floor(pos.z).." and now will reborn at spawn.")
        end
        return
    end

    bed_lives.set_lives(player, lives)
end)

minetest.register_on_leaveplayer(function(player)
	hud_ids_by_player_name[player:get_player_name()] = nil
end)

if _G["beds"] then
    local remove_bed_spawn = function(pos)
        for key, val in pairs(beds.spawn) do
            local v = vector.round(val)
            if vector.equals(v, pos) then
                beds.spawn[key] = nil
            end
        end
    end
    local old_on_destruct = minetest.registered_nodes['beds:fancy_bed_bottom'].on_destruct
    minetest.registered_nodes['beds:fancy_bed_bottom'].on_destruct = function(pos)
        old_on_destruct(pos)
        remove_bed_spawn(pos)
    end

    local old_on_destruct2 = minetest.registered_nodes['beds:fancy_bed_top'].on_destruct
    minetest.registered_nodes['beds:fancy_bed_top'].on_destruct = function(pos)
        old_on_destruct2(pos)
        remove_bed_spawn(pos)
    end

    local old_on_destruct3 = minetest.registered_nodes['beds:bed_bottom'].on_destruct
    minetest.registered_nodes['beds:bed_bottom'].on_destruct = function(pos)
        old_on_destruct3(pos)
        remove_bed_spawn(pos)
    end

    local old_on_destruct4 = minetest.registered_nodes['beds:bed_top'].on_destruct
    minetest.registered_nodes['beds:bed_top'].on_destruct = function(pos)
        old_on_destruct4(pos)
        remove_bed_spawn(pos)
    end
end

if _G["beds"] then
    -- replenish bed lives when players sleep
    local old_set_spawns = beds.set_spawns
    beds.set_spawns = function()
        old_set_spawns()
        for name, pos in pairs(beds.spawn) do
            local player = minetest.get_player_by_name(name)
            if player then
                bed_lives.set_lives(player, bed_lives.max_bed_lives)
            end
        end
    end
end
