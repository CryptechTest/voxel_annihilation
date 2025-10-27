local StructureMetaData = {}
StructureMetaData.__index = StructureMetaData

function StructureMetaData.new(def)
    local self = setmetatable({}, StructureMetaData)

    if not def then
        def = {}
    end

    local defaultAttackType = {
        ["laser"] = 0,
        ["plasma"] = 0,
        ["beam"] = 0,
        ["lightning"] = 0,
        ["flame"] = 0,
        ["emp"] = 0,
        ["kinetic"] = 0,
        ["rocket"] = 0
    }

    local merged_attack_type = {}
    for k, v in pairs(defaultAttackType) do
        if def.attack_type and def.attack_type[k] then
            merged_attack_type[k] = def.attack_type[k]
        else
            merged_attack_type[k] = v
        end
    end
    local merged_armor_type = {}
    for k, v in pairs(defaultAttackType) do
        if def.armor and def.armor[k] then
            merged_armor_type[k] = def.armor[k]
        else
            merged_armor_type[k] = v
        end
    end

    self.name = def.name or ""
    self.fqnn = def.fqnn or ""
    self.desc = def.desc or ""
    self.size = def.size or {
        x = 0,
        y = 0,
        z = 0
    }
    self.category = def.category or "none"
    self.entity_name = def.entity_name or ""
    self.tier = def.tier or 0
    self.faction = def.faction or ""
    self.volume = def.volume or 0

    -- can be damaged/destroyed by explosion
    def.is_vulnerable = def.is_vulnerable or true
    self:set_is_vulnerable(def.is_vulnerable)
    -- is volatile
    def.is_volatile = def.is_volatile or true
    self:set_is_volatile(def.is_volatile)
    -- death explosion radius
    def.death_explosion_radius = def.death_explosion_radius or 1
    self:set_death_explosion_radius(def.death_explosion_radius)
    -- self-destruct explosion radius
    def.self_explosion_radius = def.self_explosion_radius or 2
    self:set_self_explosion_radius(def.self_explosion_radius)
    -- has self-destruct countdown
    def.self_countdown = def.self_countdown or 3
    self:set_self_countdown(def.self_countdown)
    self:set_self_countdown_max(def.self_countdown)
    self:set_self_countdown_active(false)
    -- can build structures based on a list
    def.build_output_list = def.build_output_list or {}
    self:set_build_output_list(def.build_output_list)
    -- can build units based on a list
    def.build_power = def.build_power or 0
    self:set_build_power(def.build_power)
    -- has construction distance
    def.construction_distance = def.construction_distance or 0
    self:set_construction_distance(def.construction_distance)
    -- has max health
    def.max_health = def.max_health or 10
    self:set_max_health(def.max_health, true)
    -- has max shield
    def.max_shield = def.max_shield or 0
    self:set_max_shield(def.max_shield, true)
    -- has armor
    def.armor = merged_armor_type or {}
    self:set_armor(def.armor)
    -- has mass cost during construct
    def.mass_cost = def.mass_cost or 0
    self:set_mass_cost(def.mass_cost)
    -- has energy cost during construct
    def.energy_cost = def.energy_cost or 0
    self:set_energy_cost(def.energy_cost)
    -- has vision radius
    def.vision_radius = def.vision_radius or 1
    self:set_vision_radius(def.vision_radius)
    -- has radar radius
    def.radar_radius = def.radar_radius or 0
    self:set_radar_radius(def.radar_radius)
    -- has anti-radar radius
    def.antiradar_radius = def.antiradar_radius or 0
    self:set_antiradar_radius(def.antiradar_radius)
    -- has attack distance
    def.attack_distance = def.attack_distance or 0
    self:set_attack_distance(def.attack_distance)
    -- has attack power
    def.attack_power = def.attack_power or 0
    self:set_attack_power(def.attack_power)
    -- has attack type
    def.attack_type = merged_attack_type or {}
    self:set_attack_type(def.attack_type)
    -- consumes energy based on build power
    def.energy_consume = def.energy_consume or 0
    self:set_energy_consume(def.energy_consume)
    -- consumes mass based on build power
    def.mass_consume = def.mass_consume or 0
    self:set_mass_consume(def.mass_consume)
    -- generates energy based on resource or enviroment
    def.energy_generate = def.energy_generate or 0
    self:set_energy_generate(def.energy_generate)
    -- generates mass based on resource or enviroment
    def.mass_extract = def.mass_extract or 0
    self:set_mass_extract(def.mass_extract)
    -- storage for energy
    def.energy_storage = def.energy_storage or 0
    self:set_energy_storage(def.energy_storage)
    -- storage for mass
    def.mass_storage = def.mass_storage or 0
    self:set_mass_storage(def.mass_storage)
    -- are upgradable to higher tier (if available)
    def.next_upgrade = def.next_upgrade or nil
    self:set_next_upgrade(def.next_upgrade)

    return self
end

function StructureMetaData:set_is_vulnerable(value)
    self.is_vulnerable = value
end

function StructureMetaData:set_is_volatile(value)
    self.is_volatile = value
end

function StructureMetaData:set_death_explosion_radius(value)
    self.death_explosion_radius = value
end

function StructureMetaData:set_self_explosion_radius(value)
    self.self_explosion_radius = value
end

function StructureMetaData:set_self_countdown(value)
    self.self_countdown = value
end

function StructureMetaData:get_self_countdown()
    return self.self_countdown
end

function StructureMetaData:set_self_countdown_max(value)
    self.set_self_countdown_max = value
end

function StructureMetaData:get_self_countdown_max()
    return self.set_self_countdown_max
end

function StructureMetaData:is_self_destructing()
    return self.self_countdown_active
end

function StructureMetaData:set_self_countdown_active(value)
    self.self_countdown_active = value
    if value == false then
        self:set_self_countdown(self:get_self_countdown_max())
    end
end

function StructureMetaData:set_build_output_list(list)
    self.build_output_list = list
end

function StructureMetaData:get_build_output_list()
    return self.build_output_list
end

function StructureMetaData:set_build_power(value)
    self.build_power = value
end

function StructureMetaData:get_build_power()
    return self.build_power
end

function StructureMetaData:set_construction_distance(value)
    self.construction_distance = value
end

-- Getter for health
function StructureMetaData:get_health()
    return self.health
end

-- Setter for health
function StructureMetaData:set_health(value)
    self.health = value
end

-- Getter for max health
function StructureMetaData:get_max_health()
    return self.max_health
end

-- Setter for max health
function StructureMetaData:set_max_health(value, apply)
    self.max_health = value
    if apply then
        self.health = value
    end
end

-- Getter for shield
function StructureMetaData:get_shield()
    return self.shield
end

-- Setter for shield
function StructureMetaData:set_shield(value)
    self.shield = value
end

-- Getter for max shield
function StructureMetaData:get_max_shield()
    return self.max_shield
end

-- Setter for max shield
function StructureMetaData:set_max_shield(value, apply)
    self.max_shield = value
    if apply then
        self.shield = value
    end
end

function StructureMetaData:set_armor(armorTable)
    self.armor = armorTable
end

function StructureMetaData:get_armor()
    return self.armor
end

function StructureMetaData:get_mass_cost()
    return self.mass_cost
end

function StructureMetaData:set_mass_cost(value)
    self.mass_cost = value
end

function StructureMetaData:get_energy_cost()
    return self.energy_cost
end

function StructureMetaData:set_energy_cost(value)
    self.energy_cost = value
end

function StructureMetaData:get_vision_radius()
    return self.vision_radius
end

function StructureMetaData:set_vision_radius(value)
    self.vision_radius = value
end

function StructureMetaData:get_radar_radius()
    return self.radar_radius
end

function StructureMetaData:set_radar_radius(value)
    self.radar_radius = value
end

function StructureMetaData:get_antiradar_radius()
    return self.antiradar_radius
end

function StructureMetaData:set_antiradar_radius(value)
    self.antiradar_radius = value
end

function StructureMetaData:get_attack_distance()
    return self.attack_distance
end

function StructureMetaData:set_attack_distance(value)
    self.attack_distance = value
end

function StructureMetaData:get_attack_power()
    return self.attack_power
end

function StructureMetaData:set_attack_power(value)
    self.attack_power = value
end

function StructureMetaData:get_attack_type()
    return self.attack_type
end

function StructureMetaData:set_attack_type(attack_table)
    self.attack_type = attack_table
end

function StructureMetaData:get_energy_consume()
    return self.energy_consume
end

function StructureMetaData:set_energy_consume(value)
    self.energy_consume = value
end

function StructureMetaData:get_mass_consume()
    return self.mass_consume
end

function StructureMetaData:set_mass_consume(value)
    self.mass_consume = value
end

function StructureMetaData:get_energy_generate()
    return self.energy_generate
end

function StructureMetaData:set_energy_generate(value)
    self.energy_generate = value
end

function StructureMetaData:get_mass_extract()
    return self.mass_extract
end

function StructureMetaData:set_mass_extract(value)
    self.mass_extract = value
end

function StructureMetaData:get_next_upgrade()
    return self.next_upgrade
end

function StructureMetaData:get_energy_storage()
    return self.energy_storage
end

function StructureMetaData:set_energy_storage(value)
    self.energy_storage = value
end

function StructureMetaData:get_mass_storage()
    return self.mass_storage
end

function StructureMetaData:set_mass_storage(value)
    self.mass_storage = value
end

function StructureMetaData:set_next_upgrade(upgrade)
    self.next_upgrade = upgrade
end

return StructureMetaData
