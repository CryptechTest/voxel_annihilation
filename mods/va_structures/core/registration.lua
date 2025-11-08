
local modname = core.get_current_modname()
local mod_path = core.get_modpath(modname)

local register_structure_gauge = dofile(mod_path .. "/structure/structure_entity_gauge.lua")
local register_structure_build = dofile(mod_path .. "/structure/structure_entity_build.lua")
local register_construction_gauge = dofile(mod_path .. "/structure/unit/construction_entity.lua")

register_structure_gauge();
register_structure_build();
register_construction_gauge();

local lua_ext = ".lua"
local root_path = mod_path .. "/structures/"

local structure_files = {
    ['t1'] = {
        ['build'] = {
            "vox_bot_lab",
            "vox_build_turret"
        },
        ['combat'] = {
            "vox_heavy_laser_tower",
            "vox_heavy_mine",
            "vox_light_laer_tower",
            "vox_light_mine",
            "vox_medium_beam_tower",
            "vox_medium_plasma_artillery",
            "vox_pop_up_turret"
        },
        ['economy'] = {
            "vox_energy_converter",
            "vox_energy_storage",
            "vox_mass_extractor",
            "vox_naval_mass_extractor",
            "vox_mass_storage",
            "vox_solar_collector",
            "vox_wind_turbine",
            "vox_geothermal_plant",
        },
        ['utility'] = {
            "vox_anti_radar_missile",
            "vox_jammer_tower",
            "vox_lamp_tower",
            "vox_perimeter_camera",
            "vox_radar_tower",
            "vox_wall"
        }
    },
    ['t2'] = {
        ['build'] = { },
        ['combat'] = { },
        ['economy'] = { },
        ['utility'] = { }
    },
    ['t3'] = {
        ['build'] = { },
        ['combat'] = { },
        ['economy'] = { },
        ['utility'] = { }
    }
}

-- load all structures define in structure_files
local function load_structures()
    local file_list = {}
    for tier,structures in pairs(structure_files) do
        for cat,categories in pairs(structures) do
            for _,structure_name in ipairs(categories) do
                local found_file = false
                local structure_file = structure_name .. lua_ext
                local path = root_path .. tier .. "/" .. cat .. "/"
                local file = path .. structure_file
                local input = io.open(file, "r")
                if input then
                    input:close()
                    found_file = true
                end
                if found_file then
                    table.insert(file_list, {name = structure_name, path = file})
                end
            end
        end
    end
    for _,file in pairs(file_list) do
        local s = dofile(file.path)
    end
end

load_structures()
