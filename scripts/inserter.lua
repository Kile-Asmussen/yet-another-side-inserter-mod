
local util = require 'util'
local math2d = require 'math2d'
local yasilib = require 'scripts.yasilib'


script.on_event('yasi-reset-inserter-arm', function(event)
    yasilib.reset_inserter(yasilib.locate_inserter(event))
end)

script.on_event('yasi-extend-inserter-arm', function(event)
    yasilib.adjust_inserter_extension(yasilib.locate_inserter(event), 1)
end)

script.on_event('yasi-retract-inserter-arm', function(event)
    yasilib.adjust_inserter_extension(yasilib.locate_inserter(event), -1)
end)

script.on_event('yasi-rotate-inserter-pickup-sunwise', function(event)
    local turn = defines.direction.northeast
    if not player.mod_settings['yasi-8-way-rotation'].value then turn = defines.direction.east end
    yasilib.rotate_inserter_pickup(turn, yasilib.locate_inserter(event))
end)

script.on_event('yasi-rotate-inserter-pickup-widdershins', function(event)
    local turn = defines.direction.northwest
    if not player.mod_settings['yasi-8-way-rotation'].value then turn = defines.direction.west end
    yasilib.rotate_inserter_pickup(turn, yasilib.locate_inserter(event))
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
    if not yasilib.get_inserter_prototype(event.destination) then return end

    
    local saved = {
        drop = yasilib.get_drop_direction(event.destination),
        pickup = yasilib.get_pickup_direction(event.destination),
        level = yasilib.get_extension_level(event.destination),
    }

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    storage.saved[event.player_index][event.destination.unit_number] = saved
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    local player = game.get_player(event.player_index)
    if player.mod_settings['yasi-paste-inserter-directions'].value then return end
    if not yasilib.get_inserter_prototype(event.destination) then return end

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    local saved = storage.saved[event.player_index][event.destination.unit_number]
    storage.saved[event.player_index][event.destination.unit_number] = nil

    if saved then
        yasilib.set_pickup(event.destination, saved.pickup, saved.level)
        yasilib.set_drop(event.destination, saved.drop, saved.level)
    end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
    local player = game.get_player(event.player_index)
    if not player.mod_settings['yasi-8-way-rotation'].value then return end

    local inserter = event.entity
    local prototype = yasilib.get_inserter_prototype(inserter)
    if not prototype then return end
    local turn = defines.direction.northwest
    if yasilib.add_direction(event.previous_direction, defines.direction.east) == inserter.direction then
        turn = defines.direction.northeast
    end
    inserter.direction = event.previous_direction
    yasilib.rotate_inserter(inserter, yasilib.get_inserter_prototype(inserter), turn)
end)

commands.add_command('yasi-fix-inserters', {'command.yasi-fix-inserters'}, function(command)
    for i = 1, #game.surfaces do
        local surface = game.surfaces[i]

        local inserters = surface.find_entities_filtered{
            type = 'inserter'
        }

        for _, inserter in pairs(inserters) do
            if inserter.valid then
                yasilib.set_pickup(inserter)
                yasilib.set_drop(inserter)
            end
        end

        inserters = surface.find_entities_filtered{
            ghost_type = 'inserter'
        }

        for _, inserter in pairs(inserters) do
            if inserter.valid then
                yasilib.set_pickup(inserter)
                yasilib.set_drop(inserter)
            end
        end
    end
end)