va_hud = {}

dofile(core.get_modpath("va_hud") .. "/item_names.lua")

local saved_huds = {}

local function setup_hud(player)
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

    local player_name = player:get_player_name()
    saved_huds[player_name] = {}
    saved_huds[player_name]["background"] = player:hud_add({
        hud_elem_type = "image",
        position      = { x = 1, y = 0 },
        offset        = { x = -260, y = 68 },
        text          = "va_hud_resources_background.png",
        scale         = { x = 2, y = 2 },
        alignment     = 0,
    })
    if mass_storage > 0 then
        saved_huds[player_name]["mass_bar"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -460 + 2 * ((mass / mass_storage) * 100), y = 46 },
            text          = "va_hud_mass_bar.png",
            scale         = { x = 2 * ((mass / mass_storage) * 200), y = 2 },
            alignment     = 1,
        })
    else
        saved_huds[player_name]["mass_bar"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -460, y = 46 },
            text          = "va_hud_mass_bar.png",
            scale         = { x = 0, y = 2 },
            alignment     = 1,
        })
    end

    if energy_storage > 0 then
        saved_huds[player_name]["energy_bar"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -460 + 2 * ((energy / energy_storage) * 100), y = 110 },
            text          = "va_hud_energy_bar.png",
            scale         = { x = 2 * ((energy / energy_storage) * 200), y = 2 },
            alignment     = 1,
        })
    else
        saved_huds[player_name]["energy_bar"] = player:hud_add({
            hud_elem_type = "image",
            position      = { x = 1, y = 0 },
            offset        = { x = -460, y = 110 },
            text          = "va_hud_energy_bar.png",
            scale         = { x = 0, y = 2 },
            alignment     = 1,
        })
    end

    saved_huds[player_name]["mass"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -260, y = 26 },
        text          = tostring(mass) .. " / " .. tostring(mass_storage),
        alignment     = 0,
        number        = 0xFFFFFF,
        style = 5
    })

    saved_huds[player_name]["mass_demand"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -33, y = 26 },
        text          = tostring(mass_demand),
        alignment     = -1,
        number        = 0xFF0000,
        style = 4
    })

    saved_huds[player_name]["mass_supply"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -33, y = 46 },
        text          = tostring(mass_supply),
        alignment     = -1,
        number        = 0x00FF00,
        style = 4
    })

    saved_huds[player_name]["energy"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -260, y = 90 },
        text          = tostring(energy) .. " / " .. tostring(energy_storage),
        alignment     = 0,
        number        = 0xFFFFFF,
        style = 5
    })

    saved_huds[player_name]["energy_demand"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -33, y = 90 },
        text          = tostring(energy_demand),
        alignment     = -1,
        number        = 0xFF0000,
        style = 4
    })

    saved_huds[player_name]["energy_supply"] = player:hud_add({
        type = "text",
        position      = { x = 1, y = 0 },
        offset        = { x = -33, y = 110 },
        text          = tostring(energy_supply),
        alignment     = -1,
        number        = 0x00FF00,
        style = 4
    })
    if wasting_mass then
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -440, y = 26 },
            text          = "Waste",
            alignment     = -1,
            number        = 0xFF0000,
        })
    elseif overflow_mass then
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -430, y = 26 },
            text          = "Overflow",
            alignment     = -1,
            number        = 0xFFF9900,
        })
    else
        saved_huds[player_name]["notify_mass"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -430, y = 26 },
            text          = "",
            alignment     = -1,
            number        = 0x000000,
        })
    end

    if wasting_energy then
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -440, y = 90 },
            text          = "Waste",
            alignment     = -1,
            number        = 0xFF0000,
        })
    elseif overflow_energy then
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -430, y = 90 },
            text          = "Overflow",
            alignment     = -1,
            number        = 0xFF9900,
        })
    else
        saved_huds[player_name]["notify_energy"] = player:hud_add({
            hud_elem_type = "text",
            position      = { x = 1, y = 0 },
            offset        = { x = -430, y = 90 },
            text          = "",
            alignment     = -1,
            number        = 0x000000,
        })
    end
end

function va_hud.update_hud(player)
    local player_name = player:get_player_name()
    local player_actor = va_structures.get_player_actor(player_name)
    local mass = player_actor.mass
    local mass_supply = player_actor.mass_supply
    local mass_demand = player_actor.mass_demand
    local mass_storage = player_actor.mass_storage
    local storing_mass = mass_supply > mass_demand and mass < mass_storage
    local overflow_mass = mass_supply > 0 and mass >= mass_storage and
        not
        storing_mass -- this needs to be set based on if there are teammate and can overflow mass
    local wasting_mass = mass_supply > mass_demand and mass <= mass_storage and not overflow_mass and not storing_mass
    local energy = player_actor.energy
    local energy_supply = player_actor.energy_supply
    local energy_demand = player_actor.energy_demand
    local energy_storage = player_actor.energy_storage
    local storing_energy = energy_supply > energy_demand and energy < energy_storage
    local overflow_energy = energy_supply > 0 and energy >= energy_storage and
        not
        storing_energy -- this needs to be set based on if there are teammate and can overflow energy
    local wasting_energy = energy_supply > energy_demand and energy <= energy_storage and not overflow_energy and
        not storing_energy

    local ids = saved_huds[player_name]
    if ids then
        player:hud_change(ids["mass"], "text", tostring(mass) .. " / " .. tostring(mass_storage))
        player:hud_change(ids["mass_demand"], "text", tostring(mass_demand))
        player:hud_change(ids["mass_supply"], "text", tostring(mass_supply))
        player:hud_change(ids["energy"], "text", tostring(energy) .. " / " .. tostring(energy_storage))
        player:hud_change(ids["energy_demand"], "text", tostring(energy_demand))
        player:hud_change(ids["energy_supply"], "text", tostring(energy_supply))
        if mass_storage > 0 then
            player:hud_change(ids["mass_bar"], "offset", { x = -460 + 2 * ((mass / mass_storage) * 100), y = 46 })
            player:hud_change(ids["mass_bar"], "scale", { x = 2 * ((mass / mass_storage) * 200), y = 2 })
        else
            player:hud_change(ids["mass_bar"], "offset", { x = -460, y = 46 })
            player:hud_change(ids["mass_bar"], "scale", { x = 0, y = 2 })
        end
        if energy_storage > 0 then
            player:hud_change(ids["energy_bar"], "offset", { x = -460 + 2 * ((energy / energy_storage) * 100), y = 110 })
            player:hud_change(ids["energy_bar"], "scale", { x = 2 * ((energy / energy_storage) * 200), y = 2 })
        else
            player:hud_change(ids["energy_bar"], "offset", { x = -460, y = 110 })
            player:hud_change(ids["energy_bar"], "scale", { x = 0, y = 2 })
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
        local player_name = player:get_player_name()
        va_hud.update_hud(player)
    end
    core.after(1, cyclical_update)
end

cyclical_update()

core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    return 0
end)