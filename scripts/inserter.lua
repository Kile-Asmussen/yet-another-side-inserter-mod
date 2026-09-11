
local util = require 'util'
local math2d = require 'math2d'
local yasilib = require 'scripts.yasilib'


local inserter_prototypes = {}
for _, prototype in pairs(prototypes.entity) do
    if prototype.type == 'inserter' then
        inserter_prototypes[prototype.name] = prototype
    end
end

script.on_event('yasi-reset-inserter-arm', function(event)
    -- yasilib.reset_inserter(yasilib.locate_inserter(event))
    local inserter = yasilib.locate_inserter(event)
    if not inserter then return end
    yasilib.set_pickup_dropoff(inserter, inserter.direction, util.oppositedirection(inserter.direction), 2)
end)

script.on_event('yasi-extend-inserter-arm', function(event)
    yasilib.adjust_inserter_extension(yasilib.locate_inserter(event), 1)
end)

script.on_event('yasi-retract-inserter-arm', function(event)
    local inserter = yasilib.locate_inserter(event)
    yasilib.adjust_inserter_extension(yasilib.locate_inserter(event), -1)
end)

script.on_event('yasi-rotate-inserter-pickup-sunwise', function(event)
    local player = game.get_player(event.player_index)
    local turn = defines.direction.northeast
    if not player.mod_settings['yasi-8-way-rotation'].value then turn = defines.direction.east end
    yasilib.rotate_inserter_pickup(yasilib.locate_inserter(event), turn)
end)

script.on_event('yasi-rotate-inserter-pickup-widdershins', function(event)
    local player = game.get_player(event.player_index)
    local turn = defines.direction.northwest
    if not player.mod_settings['yasi-8-way-rotation'].value then turn = defines.direction.west end
    yasilib.rotate_inserter_pickup(yasilib.locate_inserter(event), turn)
end)

script.on_event('yasi-toggle-paste-inserter-directions', function(event)
    local player = game.get_player(event.player_index)
    player.mod_settings['yasi-paste-inserter-directions'] = { value = not player.mod_settings['yasi-paste-inserter-directions'].value }

    if player.mod_settings['yasi-paste-inserter-directions-notify'].value then
        if player.mod_settings['yasi-paste-inserter-directions'].value then
            game.print{'mod-setting-change.yasi-paster-inserter-directions-on'}
        else
            game.print{'mod-setting-change.yasi-paster-inserter-directions-off'}
        end
    end
end)

script.on_event(defines.events.on_pre_entity_settings_pasted, function(event)
    local player = game.get_player(event.player_index)
    if player.mod_settings['yasi-paste-inserter-directions'].value then return end

    if not yasilib.is_inserter(event.destination) then return end

    
    local saved = {
        yasilib.get_pickup_direction(event.destination),
        yasilib.get_dropoff_direction(event.destination),
        yasilib.get_extension_level(event.destination),
    }

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    storage.saved[event.player_index][event.destination.unit_number] = saved
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    if not yasilib.is_inserter(event.destination) then return end

    local player = game.get_player(event.player_index)
    if player.mod_settings['yasi-paste-inserter-directions'].value then
        yasilib.adjust_inserter_extension(0, event.destination, prototype)
        
        if yasilib.is_inserter(event.source) then
            event.destination.mirroring = event.source.mirroring
        end

        return
    end

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    local saved = storage.saved[event.player_index][event.destination.unit_number]
    storage.saved[event.player_index][event.destination.unit_number] = nil

    if saved then
        yasilib.set_pickup_dropoff(event.destination, table.unpack(saved))
    end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
    local player = game.get_player(event.player_index)
    if not player.mod_settings['yasi-8-way-rotation'].value then return end
    
    local inserter = event.entity
    if not yasilib.is_inserter(inserter) then return end

    if event.previous_mirroring ~= inserter.mirroring then return end

    local turn = defines.direction.northwest
    if yasilib.add_direction(event.previous_direction, defines.direction.east) == inserter.direction then
        turn = defines.direction.northeast
    end
    inserter.direction = event.previous_direction
    yasilib.rotate_inserter(inserter, turn)
end)

