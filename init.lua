local mod_path = "mods/the_projector/"

local imgui = load_imgui({ version = "1.25.3", mod = "the_projector" })

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

local translations = {
	title = {
		["English"] = "The Projector",
		["简体中文"] = "放映机",
	},
	current_frame = {
		["English"] = "Frame Num:",
		["简体中文"] = "当前帧编号:",
	},
	paused = {
		["English"] = "Paused",
		["简体中文"] = "当前已暂停",
	},
	not_paused = {
		["English"] = "Not paused",
		["简体中文"] = "当前未暂停",
	},
	freeze_button = {
		["English"] = "Freeze",
		["简体中文"] = "暂停",
	},
	unfreeze_button = {
		["English"] = "Unfreeze",
		["简体中文"] = "取消暂停",
	},
	step_by_button = {
		["English"] = "Step by",
		["简体中文"] = "步进",
	},
	n_frames = {
		["English"] = "frames",
		["简体中文"] = "帧",
	},
	stepping = {
		["English"] = "Stepping......",
		["简体中文"] = "步进中......",
	},
	stop_stepping_button = {
		["English"] = "Stop",
		["简体中文"] = "停止",
	},
	free_camera = {
		["English"] = "WASD Free Camera(Buggy)",
		["简体中文"] = "WASD 移动视角(有bug)",
	},
}

local text = {}
do
	local current_lang = GameTextGet( "$current_language" )
	for key, lang_table in pairs( translations ) do
		-- text[ key ] = lang_table[ current_lang ] or lang_table[ "English" ]
		text[ key ] = lang_table[ "English" ]
	end
end

local step_by_n_frames = 1
local stepping_remaining_frames = -1
local free_camera = false

function show_gui()
	if not ModSettingGet( "the_projector.gui_visible" ) then
		return
	end

	local is_frozen = get_is_frozen()

	if imgui.Begin( text.title ) then
		imgui.Text( text.current_frame )
		imgui.SameLine()
		imgui.Text( ("%.f"):format( GameGetFrameNum() ) )

		imgui.Text( is_frozen and text.paused or text.not_paused )

		if stepping_remaining_frames > 0 then
			imgui.Text( text.stepping )
			imgui.SameLine()
			if imgui.Button( text.stop_stepping_button ) then
				stepping_remaining_frames = 0
			end
		elseif is_frozen then
			if imgui.Button( text.unfreeze_button ) then
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
			if imgui.Button( text.freeze_button ) then
				freeze()
			end
		end
		imgui.End()
	end

	if stepping_remaining_frames == 0 then
		stepping_remaining_frames = -1
		freeze()
	end
	if stepping_remaining_frames > 0 then
		stepping_remaining_frames = stepping_remaining_frames - 1
		unfreeze()
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

OnWorldPreUpdate = show_gui
function OnPausePreUpdate()
	if np.GetPauseState() <= 1 then
		show_gui()
	end
	if free_camera then
		free_camera_update()
	end
end
