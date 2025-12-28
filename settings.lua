dofile( "data/scripts/lib/mod_settings.lua" )

local mod_id = "the_projector"
mod_settings_version = 1

mod_settings =
{
	{
		id = "gui_visible",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
}

local text
function load_text( cur_lang )
	if cur_lang == "简体中文" or cur_lang == "喵体中文" or cur_lang == "汪体中文" or cur_lang == "完全汉化" then
		text = {
			gui_visible = "显示界面",
		}
	else
		text = {
	   		gui_visible = "GUI Visible",
		}
	end

	local function recursive( setting )
		if setting.id ~= nil then
			setting.ui_name = text[ setting.id ]
			setting.ui_description = text[ setting.id .. "_description" ]
			if text[ setting.id .. "_values" ] ~= nil then
				setting.values = text[ setting.id .. "_values" ]
				setting.value_default = setting.values[1][1]
			end
			setting.scope = setting.scope or MOD_SETTING_SCOPE_RUNTIME
		elseif setting.category_id ~= nil then
			setting.ui_name = text[ setting.category_id ]
			setting.ui_description = text[ setting.category_id .. "_description" ]
			for _, s in ipairs( setting.settings ) do
				recursive( s )
			end
		end
	end
	for _, s in ipairs( mod_settings ) do
		recursive( s )
	end
end

load_text( GameTextGet( "$current_language" ) )

function ModSettingsUpdate( init_scope )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	local cur_lang = GameTextGet( "$current_language" )
	if cur_lang ~= last_cur_lang then
		load_text( cur_lang )
		last_cur_lang = cur_lang
	end
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
