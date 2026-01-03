local mod_path = "mods/the_projector/"

dofile_once( mod_path .. "NoitaPatcher/load.lua" )
local np = require( "noitapatcher" )

function freeze()
	np.SetPauseState( bit.bor( np.GetPauseState(), 1 ) )
end
function unfreeze()
	np.SetPauseState( bit.bor( np.GetPauseState(), 1 ) - 1 )
end
function get_is_frozen()
	return np.GetPauseState() % 2 == 1
end

local systems = dofile_once( mod_path .. "systems.lua" )
local updates = dofile_once( mod_path .. "updates.lua" )

local text = {}
do
	local translations = dofile_once( mod_path .. "translations.lua" )
	-- local current_lang = GameTextGet( "$current_language" )
	for key, lang_table in pairs( translations ) do
		-- text[ key ] = lang_table[ current_lang ] or lang_table[ "English" ]
		text[ key ] = lang_table[ "English" ]
	end
end

local imgui = load_imgui({ version = "1.25.3", mod = "the_projector" })

local step_by_n_frames = 1
local stepping_remaining_frames = -1
local free_camera = false
local update_enabled = {}
local update_breakpointed = {}
local current_breakpoint = nil
local num_updates = #updates.list

local window_open_update_list = false
local window_open_breakpoint_list = false

for i, _ in ipairs( updates.list ) do
	update_enabled[ i ] = true
end

function show_gui()
	if not ModSettingGet( "the_projector.gui_visible" ) then
		return
	end

	local is_frozen = get_is_frozen()

	if imgui.Begin( text.title ) then
		_, window_open_update_list = imgui.Checkbox( text.title_update_list, window_open_update_list )
		imgui.SameLine()
		_, window_open_breakpoint_list = imgui.Checkbox( text.title_breakpoint_list, window_open_breakpoint_list )

		imgui.Separator()

		imgui.Text( text.current_frame )
		imgui.SameLine()
		imgui.Text( string.format( "%.f", GameGetFrameNum() ) )

		imgui.Text( is_frozen and text.paused or text.not_paused )

		if stepping_remaining_frames > 0 then
			imgui.Text( text.stepping )
			imgui.SameLine()
			if imgui.Button( text.stop_stepping_button ) then
				stepping_remaining_frames = 0
			end
		elseif is_frozen then
			if imgui.Button( text.button_unfreeze ) then
				unfreeze()
			end

			if imgui.Button( text.step_by_button ) then
				stepping_remaining_frames = step_by_n_frames
				unfreeze()
			end
			imgui.SameLine()
			imgui.SetNextItemWidth(120)
			_, step_by_n_frames = imgui.InputInt( "", step_by_n_frames )
			imgui.SameLine()
			imgui.Text( text.n_frames )

			_, free_camera = imgui.Checkbox( text.free_camera, free_camera )
		else
			if imgui.Button( text.button_freeze ) then
				freeze()
			end
		end

		imgui.End()
	end

	if window_open_update_list and imgui.Begin( string.format( "%s - %s", text.title, text.title_update_list ) ) then
		local table_flags = bit.bor( imgui.TableFlags.Resizable, imgui.TableFlags.Hideable, imgui.TableFlags.RowBg )
		if imgui.BeginTable( "updates_table", 4, table_flags ) then
			imgui.TableSetupColumn( text.column_number, imgui.TableColumnFlags.WidthFixed )
			imgui.TableSetupColumn( text.column_enabled, imgui.TableColumnFlags.WidthFixed )
			imgui.TableSetupColumn( text.column_name, imgui.TableColumnFlags.WidthStretch, 6 )
			imgui.TableSetupColumn( text.breakpoint_column, imgui.TableColumnFlags.WidthFixed )
			imgui.TableHeadersRow()

			for i, name in ipairs( updates.list ) do
				imgui.PushID( name )

				imgui.TableNextColumn()
				imgui.Text( tostring( i ) )

				imgui.TableNextColumn()
				_, update_enabled[ i ] = imgui.Checkbox( "", update_enabled[ i ] )
				if update_breakpointed[ i ] then
					imgui.SameLine()
					local image_breakpointed = imgui.LoadImage( mod_path .. "breakpointed.png" )
					imgui.Image( image_breakpointed, 20, 20 )
				end

				imgui.TableNextColumn()
				imgui.Text( name )

				imgui.TableNextColumn()
				_, update_breakpointed[ i ] = imgui.Checkbox( text.breakpoint_column, update_breakpointed[ i ] == true )

				if i == current_breakpoint then
					imgui.TableSetBgColor( imgui.TableBgTarget.RowBg1, 1, 0, 0, 1 )
				end

				imgui.PopID()
			end
			imgui.EndTable()
		end
		imgui.End()
	end

	if window_open_breakpoint_list and imgui.Begin( string.format( "%s - %s", text.title, text.title_breakpoint_list ) ) then
		local empty = true

		for i, name in ipairs( updates.list ) do
			if i == current_breakpoint then
				imgui.TextColored( 1, 0, 0, 1, string.format( ">> %d. %s", i, name ) )
				empty = false
			elseif update_breakpointed[ i ] then
				imgui.Text( string.format( "%d. %s", i, name ) )
				empty = false
			end
		end

		if empty then
			imgui.Text( "No breakpoints set." )
		end

		imgui.End()
	end

	step_logic()
end

function step_logic()
	if stepping_remaining_frames > 0 then
		stepping_remaining_frames = stepping_remaining_frames - 1
		unfreeze()
	elseif stepping_remaining_frames == 0 then
		stepping_remaining_frames = -1
		freeze()
	end
end

local keycodes = {
	Key_w = 26,
	Key_a = 4,
	Key_s = 22,
	Key_d = 7,
}

function free_camera_update()
	local x, y = GameGetCameraPos()
	local speed = 10
	if InputIsKeyDown( keycodes.Key_w ) then
		y = y - speed
	end
	if InputIsKeyDown( keycodes.Key_s ) then
		y = y + speed
	end
	if InputIsKeyDown( keycodes.Key_a ) then
		x = x - speed
	end
	if InputIsKeyDown( keycodes.Key_d ) then
		x = x + speed
	end
	GameSetCameraPos( x, y )
end

function OnWorldPreUpdate()
	show_gui()

	local last_breakpoint = current_breakpoint or 0
	current_breakpoint = nil
	for i = last_breakpoint + 1, num_updates do
		if update_breakpointed[ i ] then
			current_breakpoint = i
			break
		end
	end

	for i, name in ipairs( updates.list ) do
		local enabled = update_enabled[ i ]

		if last_breakpoint ~= nil then
			enabled = enabled and last_breakpoint <= i
		end

		if current_breakpoint ~= nil then
			enabled = enabled and i < current_breakpoint
		end

		updates.set_enabled( name, enabled )
	end

	if current_breakpoint ~= nil then
		freeze()
	end
end
function OnPausePreUpdate()
	if np.GetPauseState() <= 1 then
		show_gui()
	end
	if free_camera then
		free_camera_update()
	end
end
