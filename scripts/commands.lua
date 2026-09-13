
local yasilib = require 'scripts.yasilib'

local delay = 3 * second

local inserter_prototypes = {}
for _, prototype in pairs(prototypes.entity) do
    if prototype.type == 'inserter' then
        inserter_prototypes[prototype.name] = prototype
    end
end

commands.add_command('yasi-fix-inserters', {'command.yasi-fix-inserters'}, function(command)
    storage.last_invocation = storage.last_invocation or {}

    storage.last_invocation['yasi-fix-inserters'] = storage.last_invocation['yasi-fix-inserters'] or {}

    storage.last_invocation['yasi-fix-inserters'][command.player_index]
        = storage.last_invocation['yasi-fix-inserters'][command.player_index] or -delay

    if command.tick - storage.last_invocation['yasi-fix-inserters'][command.player_index] > delay then
        game.print{"command.yasi-fix-inserters-waring"}
        storage.last_invocation['yasi-fix-inserters'][command.player_index] = command.tick
        return
    end

    storage.last_invocation['yasi-fix-inserters'][command.player_index] = nil
        game.print{"command.yasi-fix-inserters-executed"}

    if storage.warning then
        for _, surface in pairs(game.surfaces) do
            for _, prototype in pairs(inserter_prototypes) do
                local inserters = surface.find_entities_filtered{
                    type = 'inserter', name = prototype.name
                }

                for _, inserter in pairs(inserters) do
                    if inserter.valid then
                        if inserter.name == 'long-handed-inserter' then
                            yasilib.set_pickup_dropoff(inserter, nil, nil, 4)
                        else
                            yasilib.set_pickup_dropoff(inserter, nil, nil, 2)
                        end
                    end
                end
            end
        end
    end
end)