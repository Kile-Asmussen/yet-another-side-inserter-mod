
local util = require 'util'

local short_inserters = {}
local long_inserters = {}

for _, inserter in pairs(data.raw.inserter) do
    
    inserter.allow_custom_vectors = true
    inserter.allow_burner_leech = true
    
    inserter.pickup_position = { 0, -1 }
    inserter.insert_position = { 0, 1.2 }
    inserter.starting_distance = 0.85

    if inserter.extension_speed >= 0.05 then
        inserter.fast_replaceable_group = 'long-handed-inserter'
        inserter.hand_size = 1.3

        if not inserter.hidden then
            table.insert(long_inserters, inserter)
        end
    else
        inserter.fast_replaceable_group = 'inserter'

        if not inserter.hidden then
            table.insert(short_inserters, inserter)
        end
    end

    if inserter.energy_source.type == 'electric' then

        local rotations = 5
        local frequency = inserter.rotation_speed * second -- Hz
        local time = rotations / frequency

        local upkeep = util.parse_energy(inserter.energy_source.drain or '0W') * second * time -- J

        local rotate = util.parse_energy(inserter.energy_per_rotation) * rotations -- J

        inserter.energy_source.buffer_size = 
            (upkeep + rotate) / 1000 .. 'kJ'
    end
end

local energy_source_hierarchy = {
    burner = 1,
    fluid = 2,
    heat = 3,
    electric = 4,
    void = 5
}

local function inserter_ordering(ins1, ins2)
    local ordering1 = data.raw.item[ins1.name] and data.raw.item[ins1.name].ordering
                    or data.raw.recipe[ins1.name] and data.raw.recipe[ins1.name].ordering
                    or ''
    
    local ordering2 = data.raw.item[ins2.name] and data.raw.item[ins2.name].ordering
                or data.raw.recipe[ins2.name] and data.raw.recipe[ins2.name].ordering
                or ''

    return ins1.rotation_speed < ins2.rotation_speed
        or ins1.extension_speed < ins2.extension_speed
        or energy_source_hierarchy[ins1.energy_source.type] < energy_source_hierarchy[ins2.energy_source.type]
        or ordering1 < ordering2
end

table.sort(
    short_inserters, inserter_ordering
)

table.sort(
    long_inserters, inserter_ordering
)

for i=1,#short_inserters-1 do
    short_inserters[i].next_upgrade = short_inserters[i+1].name
end
short_inserters[#short_inserters].next_upgrade = nil

for i=1,#long_inserters-1 do
    long_inserters[i].next_upgrade = long_inserters[i+1].name
end
long_inserters[#long_inserters].next_upgrade = nil