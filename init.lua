local mod_path = "mods/the_projector/"

local imgui = load_imgui({ version = "1.25.3", mod = "the_projector" })

do
	dofile_once( mod_path .. "NoitaPatcher/load.lua" )
	local np = require( "noitapatcher" )
	function freeze()
		np.SetPauseState(1)
	end
	function unfreeze()
		np.SetPauseState(0)
	end
	function get_pause_state()
		return np.GetPauseState()
	end
end

local translations = {
	title = {
		["English"] = "The Projector",
		["简体中文"] = "放映机",
	},
	current_frame = {
		["English"] = "Frame Num: %d",
		["简体中文"] = "当前帧编号: %d",
	},
	pause_state = {
		["English"] = "Pause State: %s(%d)",
		["简体中文"] = "暂停状态: %s(%d)",
	},
	pause_state_paused = {
		["English"] = "Paused",
		["简体中文"] = "已暂停",
	},
	pause_state_running = {
		["English"] = "Not Paused",
		["简体中文"] = "未暂停",
	},
	pause_state_stepping = {
		["English"] = "Stepping",
		["简体中文"] = "步进中",
	},
	pause_state_escape_menu = {
		["English"] = "Escape Menu",
		["简体中文"] = "Esc 菜单暂停",
	},
	pause_state_unknown = {
		["English"] = "Unknown",
		["简体中文"] = "未知",
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
	stop_stepping_button = {
		["English"] = "Stop Stepping",
		["简体中文"] = "停止步进",
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

local pause_state_to_text = {
	[0] = "pause_state_running",
	[1] = "pause_state_paused",
	[4] = "pause_state_escape_menu",
}

function get_pause_state_text( state )
	local key = pause_state_to_text[ state ]
	if state == 0 and stepping_remaining_frames >= 0 then
		key = "pause_state_stepping"
	end
	return text[ key or "pause_state_unknown" ]
end

function show_gui()
	local pause_state = get_pause_state()

	if imgui.Begin( text.title ) then
		imgui.Text( text.current_frame:format( GameGetFrameNum() ) )

		imgui.Text( text.pause_state:format( get_pause_state_text( pause_state ), pause_state ) )

		if stepping_remaining_frames > 0 then
			if imgui.Button( text.stop_stepping_button ) then
				stepping_remaining_frames = 0
			end
		else
			if pause_state == 1 then
				if imgui.Button( text.unfreeze_button ) then
					unfreeze()
				end
			elseif pause_state == 0 then
				if imgui.Button( text.freeze_button ) then
					freeze()
				end
			end

			if pause_state == 1 then
				if imgui.Button( text.step_by_button ) then
					stepping_remaining_frames = step_by_n_frames
					unfreeze()
				end
				imgui.SameLine()
				imgui.SetNextItemWidth(120)
				_, step_by_n_frames = imgui.InputInt( "", step_by_n_frames )
				imgui.SameLine()
				imgui.Text( text.n_frames )
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
	end
end

OnPausePreUpdate = show_gui
OnWorldPreUpdate = show_gui
