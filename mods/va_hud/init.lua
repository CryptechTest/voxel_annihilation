va_hud = {}

dofile(core.get_modpath("va_hud") .. "/item_names.lua")

local saved_huds = {}

local function round(number, steps)
    steps = steps or 1
    if steps == 2 then
        return math.floor(number * 10) * 0.1
    elseif steps == 3 then
        return math.floor(number * 100) * 0.01
    end
    return math.floor(number * steps + 0.5) / steps
end

local function setup_hud(player)
    local player_name = player:get_player_name()
    local window_info = core.get_player_window_information(player_name)
    local scale = 1.5
    if window_info then
        local hud_scaling = window_info.real_hud_scaling or 1
        local gui_scaling = window_info.real_gui_scaling or 1
        local touch_controls = window_info.touch_controls or false
        if touch_controls then
            scale = 1.5
        elseif window_info.size.y >= 1360 then
            scale = 2.5
        elseif window_info.size.y >= 1040 then
            scale = 2
        else
            scale = 1.5
        end
        if not touch_controls then
            scale = scale * hud_scaling * gui_scaling
        end
    end
    local mass = 0
    local mass_supply = 0
    local mass_demand = 0
    local mass_storage = 0
    local storing_mass = mass_supply > mass_demand and mass < mass_storage
    local overflow_mass = mass_supply > 0 and mass >= mass_storage and
        not
        storing_mass -- this needs to be set based on if there are teammate and can overflow mass
    local wasting_mass = mass_supply > mass_demand and mass <= mass_storage and not overflow_mass and not storing_mass
    local energy = 0
    local energy_supply = 0
    local energy_demand = 0
    local energy_storage = 0
    local storing_energy = energy_supply > energy_demand and energy < energy_storage
    local overflow_energy = energy_supply > 0 and energy >= energy_storage and
        not
        storing_energy -- this needs to be set based on if there are teammate and can overflow energy
    local wasting_energy = energy_supply > energy_demand and energy <= energy_storage and not overflow_energy and
        not storing_energy

    saved_huds[player_name] = {}
    saved_huds[player_name]["background"] = player:hud_add({
        type = "image",
        position      = { x = 1, y = 0 },
        offset        = { x = -130 * scale, y = 34 * scale },
        text          = "va_hud_resources_background.png",
        scale         = { x = scale, y = scale },
        alignment     = 0,
    })
    if mass_storage > 0 then
        saved_huds[player_name]["mass_bar"] = player:hud_add({
            type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -230 * scale, y = 23 * scale },
            text          = "va_hud_mass_bar.png",
            scale         = { x = scale * 200 * (mass / mass_storage), y = scale },
            alignment     = 1,
        })
    else
        saved_huds[player_name]["mass_bar"] = player:hud_add({
            type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -230 * scale, y = 23 * scale },
            text          = "va_hud_mass_bar.png",
            scale         = { x = 0, y = scale },
            alignment     = 1,
        })
    end

    if energy_storage > 0 then
        saved_huds[player_name]["energy_bar"] = player:hud_add({
            type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -230 * scale, y = 55 * scale },
            text          = "va_hud_energy_bar.png",
            scale         = { x = scale * 200 * (energy / energy_storage), y = scale },
            alignment     = 1,
        })
    else
        saved_huds[player_name]["energy_bar"] = player:hud_add({
            type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -230 * scale, y = 55 * scale },
            text          = "va_hud_energy_bar.png",
            scale         = { x = 0, y = scale },
            alignment     = 1,
        })
    end

    saved_huds[player_name]["mass"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -130 * scale, y = 13 * scale },
        text          = tostring(mass) .. " / " .. tostring(mass_storage),
        alignment     = 0,
        number        = 0xFFFFFF,
        style = 5
    })

    saved_huds[player_name]["mass_demand"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -16.5 * scale, y = 13 * scale },
        text          = tostring(mass_demand),
        alignment     = -1,
        number        = 0xFF0000,
        style = 4
    })

    saved_huds[player_name]["mass_supply"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -16.5 * scale, y = 23 * scale },
        text          = tostring(mass_supply),
        alignment     = -1,
        number        = 0x00FF00,
        style = 4
    })

    saved_huds[player_name]["energy"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -130 * scale, y = 45 * scale },
        text          = tostring(energy) .. " / " .. tostring(energy_storage),
        alignment     = 0,
        number        = 0xFFFFFF,
        style = 5
    })

    saved_huds[player_name]["energy_demand"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -16.5 * scale, y = 45 * scale },
        text          = tostring(energy_demand),
        alignment     = -1,
        number        = 0xFF0000,
        style = 4
    })

    saved_huds[player_name]["energy_supply"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -16.5 * scale, y = 55 * scale },
        text          = tostring(energy_supply),
        alignment     = -1,
        number        = 0x00FF00,
        style = 4
    })
    if wasting_mass then
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -220 * scale, y = 13 * scale },
            text          = "Waste",
            alignment     = -1,
            number        = 0xFF0000,
        })
    elseif overflow_mass then
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -215 * scale, y = 13 * scale },
            text          = "Overflow",
            alignment     = -1,
            number        = 0xFFF9900,
        })
    else
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -215 * scale, y = 13 * scale },
            text          = "",
            alignment     = -1,
            number        = 0x000000,
        })
    end

    if wasting_energy then
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -220 * scale, y = 45 * scale },
            text          = "Waste",
            alignment     = -1,
            number        = 0xFF0000,
        })
    elseif overflow_energy then
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -215 * scale, y = 45 * scale },
            text          = "Overflow",
            alignment     = -1,
            number        = 0xFF9900,
        })
    else
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -215 * scale, y = 45 * scale },
            text          = "",
            alignment     = -1,
            number        = 0x000000,
        })
    end
end

function va_hud.update_hud(player)
    local player_name = player:get_player_name()
    local window_info = core.get_player_window_information(player_name)
    local scale = 1.5
    if window_info then
        local hud_scaling = window_info.real_hud_scaling or 1
        local gui_scaling = window_info.real_gui_scaling or 1
        local touch_controls = window_info.touch_controls or false
        if touch_controls then
            scale = 1.5
        elseif window_info.size.y >= 1360 then
            scale = 2.5
        elseif window_info.size.y >= 1040 then
            scale = 2
        else
            scale = 1.5
        end
        if not touch_controls then
            scale = scale * hud_scaling * gui_scaling
        end
    end
    local player_actor = va_structures.get_player_actor(player_name)
    local mass = round(player_actor.mass, 2)
    local mass_supply = round(player_actor.mass_supply, 3)
    local mass_demand = round(player_actor.mass_demand, 3)
    local mass_storage = round(player_actor.mass_storage, 2)
    local storing_mass = mass_supply > mass_demand and mass < mass_storage
    local overflow_mass = mass_supply > 0 and mass >= mass_storage and
        not
        storing_mass -- this needs to be set based on if there are teammate and can overflow mass
    local wasting_mass = mass_supply > mass_demand and mass <= mass_storage and not overflow_mass and not storing_mass
    local energy = round(player_actor.energy, 2)
    local energy_supply = round(player_actor.energy_supply, 3)
    local energy_demand = round(player_actor.energy_demand, 3)
    local energy_storage = round(player_actor.energy_storage, 2)
    local storing_energy = energy_supply > energy_demand and energy < energy_storage
    local overflow_energy = energy_supply > 0 and energy >= energy_storage and
        not
        storing_energy -- this needs to be set based on if there are teammate and can overflow energy
    local wasting_energy = energy_supply > energy_demand and energy <= energy_storage and not overflow_energy and
        not storing_energy

    local ids = saved_huds[player_name]
    if ids then
        player:hud_change(ids["background"], "offset", { x = -130 * scale, y = 34 * scale })
        player:hud_change(ids["background"], "scale", { x = scale, y = scale })
        player:hud_change(ids["mass"], "offset", { x = -130 * scale, y = 13 * scale })
        player:hud_change(ids["mass"], "text", tostring(mass) .. " / " .. tostring(mass_storage))
        player:hud_change(ids["mass_demand"], "offset", { x = -16.5 * scale, y = 13 * scale })
        player:hud_change(ids["mass_demand"], "text", tostring(mass_demand))
        player:hud_change(ids["mass_supply"], "offset", { x = -16.5 * scale, y = 23 * scale })
        player:hud_change(ids["mass_supply"], "text", tostring(mass_supply))
        player:hud_change(ids["energy"], "offset", { x = -130 * scale, y = 45 * scale })
        player:hud_change(ids["energy"], "text", tostring(energy) .. " / " .. tostring(energy_storage))
        player:hud_change(ids["energy_demand"], "offset", { x = -16.5 * scale, y = 45 * scale })
        player:hud_change(ids["energy_demand"], "text", tostring(energy_demand))
        player:hud_change(ids["energy_supply"], "offset", { x = -16.5 * scale, y = 55 * scale })
        player:hud_change(ids["energy_supply"], "text", tostring(energy_supply))
        if mass_storage > 0 then
            player:hud_change(ids["mass_bar"], "offset", { x = (-230 * scale) + scale * ((mass / mass_storage) * 100), y = 23 * scale })
            player:hud_change(ids["mass_bar"], "scale", { x = scale * ((mass / mass_storage) * 200), y = scale })
        else
            player:hud_change(ids["mass_bar"], "offset", { x = -230 * scale, y = 23 * scale })
            player:hud_change(ids["mass_bar"], "scale", { x = 0, y = scale})
        end
        if energy_storage > 0 then
            player:hud_change(ids["energy_bar"], "offset", { x = (-230 * scale) + scale * ((energy / energy_storage) * 100), y = 55 * scale })
            player:hud_change(ids["energy_bar"], "scale", { x = scale * ((energy / energy_storage) * 200), y = scale })
        else
            player:hud_change(ids["energy_bar"], "offset", { x = -230 * scale, y = 55 * scale })
            player:hud_change(ids["energy_bar"], "scale", { x = 0, y = scale })
        end
        if wasting_mass then
            player:hud_change(ids["notify_mass"], "text", "Waste")
            player:hud_change(ids["notify_mass"], "number", 0xFF0000)
        elseif overflow_mass then
            player:hud_change(ids["notify_mass"], "text", "Overflow")
            player:hud_change(ids["notify_mass"], "number", 0xFF9900)
        else
            player:hud_change(ids["notify_mass"], "text", "")
            player:hud_change(ids["notify_mass"], "number", 0x000000)
        end
        if wasting_energy then
            player:hud_change(ids["notify_energy"], "text", "Waste")
            player:hud_change(ids["notify_energy"], "number", 0xFF0000)
        elseif overflow_energy then
            player:hud_change(ids["notify_energy"], "text", "Overflow")
            player:hud_change(ids["notify_energy"], "number", 0xFF9900)
        else
            player:hud_change(ids["notify_energy"], "text", "")
            player:hud_change(ids["notify_energy"], "number", 0x000000)
        end
        return
    else
        setup_hud(player)
    end
end


core.register_on_joinplayer(function(player)
    va_hud.update_hud(player)
end)

core.register_on_leaveplayer(function(player, timed_out)
    local player_name = player:get_player_name()
    saved_huds[player_name] = nil
end)

local function cyclical_update()
    for _, player in pairs(core.get_connected_players()) do
        va_hud.update_hud(player)
    end
    core.after(1, cyclical_update)
end


core.register_on_mods_loaded(function()
    core.after(1, cyclical_update)
end)


core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    return 0
end)