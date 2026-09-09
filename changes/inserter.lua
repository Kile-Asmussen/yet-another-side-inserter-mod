
data.raw.inserter.inserter.rotation_speed = 0.015
data.raw.inserter.inserter.extension_speed = 0.04
data.raw.inserter['burner-inserter'].rotation_speed = 0.015
data.raw.inserter['burner-inserter'].extension_speed = 0.04

data.raw.inserter.inserter.energy_source.drain = nil

if not settings.startup['yasi-vanilla-recipes'].value then

    data.raw.recipe['long-handed-inserter'].ingredients = {
        { type = 'item', name = 'iron-plate', amount = 2 },
        { type = 'item', name = 'iron-gear-wheel', amount = 2 },
        { type = 'item', name = 'electronic-circuit', amount = 2 },
    }

    data.raw.recipe['fast-inserter'].ingredients = {
        { type = 'item', name = 'long-handed-inserter', amount = 1 },
        { type = 'item', name = 'electronic-circuit', amount = 1 },
        { type = 'item', name = 'steel-plate', amount = 1 },
    }

end 

data.raw.inserter['long-handed-inserter'].next_upgrade = 'fast-inserter'

data.raw.technology['fast-inserter'].prerequisites = { 'automation', 'steel-processing' }