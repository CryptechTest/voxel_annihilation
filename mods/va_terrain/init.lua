--[[
Add natural slopes to Voxel Annihilation
--]]
naturalslopeslib.propagate_overrides()

local path = core.get_modpath(core.get_current_modname())
dofile(path .."/functions.lua")

naturalslopeslib.default_definition.drop_source = true
naturalslopeslib.default_definition.tiles = {{align_style = "world"}}
naturalslopeslib.default_definition.groups = {not_in_creative_inventory = 1}
naturalslopeslib.default_definition.use_texture_alpha = "clip"

dofile(path .."/nodes.lua")

naturalslopeslib.reset_defaults()

