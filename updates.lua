local mod_path = "mods/the_projector/"

dofile_once( mod_path .. "NoitaPatcher/load.lua" )
local np = require( "noitapatcher" )
local systems = dofile_once( mod_path .. "systems.lua" )

local updates = {}

do
	local list = {}

	list[1] = "GameGlobalUpdate"

	for i, system in ipairs( systems ) do
		list[ #list + 1 ] = system
	end

	list[ #list + 1 ] = "GameWorldUpdate"

	updates.list = list
end

local update_enabled = {}

for _, name in ipairs( updates.list ) do
	update_enabled[ name ] = true
end

function updates.set_enabled( name, enabled )
	update_enabled[ name ] = enabled
	if name == "GameGlobalUpdate" then
		np.EnableGameGlobalUpdate( enabled )
	elseif name == "GameWorldUpdate" then
		np.EnableGameWorldUpdate( enabled )
	else
		np.ComponentUpdatesSetEnabled( name, enabled )
	end
end

function updates.get_enabled( name )
	return update_enabled[ name ] or false
end

return updates
