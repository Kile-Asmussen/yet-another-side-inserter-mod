
local util = require 'util'

for _, inserter in pairs(data.raw.inserter) do
    
    inserter.allow_custom_vectors = true
    inserter.allow_burner_leech = true
    
    inserter.pickup_position = { 0, -1 }
    inserter.insert_position = { 0, 1.2 }
    inserter.starting_distance = 0.85

    if inserter.extension_speed > 0.05 then
        inserter.fast_replaceable_group = 'long-handed-inserter'
        inserter.hand_size = 1.3
    else
        inserter.fast_replaceable_group = 'inserter'
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
