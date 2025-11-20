core.register_node("va_game:board_barrier", {
    description = "Barrier",
    drawtype = "glasslike",
    tiles = {"water_thin.png"},
    paramtype = "light",
    light_source = 2,
    use_texture_alpha = "blend",
    sunlight_propagates = true,
    walkable = true,
    pointable = false,
    buildable_to = true,
    drop = "",
    groups = {
        level = 1,
        not_in_creative_inventory = 1
    },
    on_construct = function(pos) end,
    can_dig = function(pos, player)
        local wielded_item = player:get_wielded_item():get_name()
        return wielded_item == "barrier:barrier_item"
    end,
    sounds = {
        footstep = {name = "", gain = 0},
        dig = {name = "default_dig_cracky", gain = 1},
        dug = {name = "default_break_glass", gain = 1},
        place = {name = "", gain = 0},
    },
    on_blast = function() end
})