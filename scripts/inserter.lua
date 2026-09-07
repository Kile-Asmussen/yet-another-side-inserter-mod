
local util = require 'util'
local math2d = require 'math2d'

local number_of_directions = table_size(defines.direction)

local function add_direction(direction, turn)
    return (direction + turn) % number_of_directions
end

local function ortho_or_diagonal(direction)
    return direction % defines.direction.east
end

local function dot_product(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end
 
local pickup_offset = {
    [defines.direction.north] = { 1, 1, 2, 2 },
    [defines.direction.northeast] = { 1.1, 1.1, 2.2, 2.2 },
}

local drop_offset = {
    [defines.direction.north] = { 0.7, 1.2, 1.7, 2.2 },
    [defines.direction.northeast] = { 0.8, 1.3, 1.8, 2.3 },
}
local direction_vectors = {}

for _, dir in pairs{ 'north', 'northeast', 'east', 'southeast', 'south', 'southwest', 'west', 'northwest' } do
    dir = defines.direction[dir]
    direction_vectors[dir] = math2d.position.get_normalised(util.direction_vectors[dir])
end


local function get_drop_offset(inserter)
    return math2d.position.subtract(inserter.drop_position, inserter.position)
end

local function get_pickup_offset(inserter)
    return math2d.position.subtract(inserter.pickup_position, inserter.position)
end

local function vector_to_direction(vector)
    local length = math.sqrt(dot_product(vector, vector))
    local min = length - 0.001
    local max = length + 0.001
    for dir, normal in pairs(direction_vectors) do
        local proj = dot_product(vector, normal)
        if min < proj and proj < max then return dir end
    end
end

local function get_pickup_direction(inserter)
    return vector_to_direction(get_pickup_offset(inserter)) or inserter.direction
end

local function get_drop_direction(inserter)
    return vector_to_direction(get_drop_offset(inserter)) or util.oppositedirection(inserter.direction)
end


local function get_extension_level(inserter)
    local offset = get_drop_offset(inserter)
    local direction = vector_to_direction(offset)
    local distance = math.sqrt(dot_product(offset, offset))
    local drops = drop_offset[ortho_or_diagonal(direction)]
    for i=1, #drops do
        if math.abs(drops[i] - distance) < 0.2 then return i end
    end
    return 2
end

local function get_max_extension_level(prototype)
    local speed = prototype.get_inserter_extension_speed('normal')
    if speed < 0.05 then return 2 else return 4 end
end

local function set_pickup(inserter, direction, level)
    level = level or get_extension_level(inserter)
    direction = direction or get_pickup_direction(inserter)
    local offset = math2d.position.multiply_scalar(direction_vectors[direction], pickup_offset[ortho_or_diagonal(direction)][level])
    inserter.pickup_position = math2d.position.add(inserter.position, offset)
end

local function set_drop(inserter, direction, level)
    level = level or get_extension_level(inserter)
    direction = direction or get_drop_direction(inserter)
    local offset = math2d.position.multiply_scalar(direction_vectors[direction], drop_offset[ortho_or_diagonal(direction)][level])
    inserter.drop_position = math2d.position.add(inserter.position, offset)
end

local function adjust_inserter_extension(inserter, prototype, adjustment)
    if not inserter then return end
    local level = get_extension_level(inserter)
    local max = get_max_extension_level(prototype)
    next_level = util.clamp(level + adjustment, 1, max)
    set_pickup(inserter, nil, next_level)
    set_drop(inserter, nil, next_level)
end


local function rotate_inserter_pickup(inserter, prototype, turn)
    if not inserter then return end
    local new_direction = add_direction(get_pickup_direction(inserter), turn)
    set_pickup(inserter, new_direction, nil)
end

local cardinals = {
    [defines.direction.north] = true,
    [defines.direction.east] = true,
    [defines.direction.south] = true,
    [defines.direction.west] = true,
}

local function rotate_inserter(inserter, prototype, turn)
    if not inserter then return end

    local pickup_direction = add_direction(get_pickup_direction(inserter), turn)
    local drop_direction = add_direction(get_drop_direction(inserter), turn)

    if cardinals[drop_direction] then inserter.direction = util.oppositedirection(drop_direction) end

    set_pickup(inserter, pickup_direction, nil)
    set_drop(inserter, drop_direction, nil)
end

local function reset_inserter(inserter, prototype)
    if not inserter then return end
    set_pickup(inserter, util.oppositedirection(inserter.direction), 2)
    set_drop(inserter, inserter.direction, 2)
end

local function get_inserter_prototype(inserter)
    if inserter.type == 'inserter' then return inserter.prototype end
    if inserter.type == 'entity-ghost' and inserter.ghost_type == 'inserter' then return inserter.ghost_prototype end
end

local function locate_inserter(callback, ...)
    local args = { ... }
    return function(event)
        local player = game.get_player(event.player_index)

        if not player.selected then return end
        
        local entity = player.selected

        local prototype = get_inserter_prototype(entity)

        if prototype then callback(entity, prototype, table.unpack(args)) end
    end
end


script.on_event('yasi-reset-inserter-arm', locate_inserter(reset_inserter))
script.on_event('yasi-extend-inserter-arm', locate_inserter(adjust_inserter_extension, 1))
script.on_event('yasi-retract-inserter-arm', locate_inserter(adjust_inserter_extension, -1))
script.on_event('yasi-rotate-inserter-pickup-sunwise', locate_inserter(rotate_inserter_pickup, defines.direction.northeast))
script.on_event('yasi-rotate-inserter-pickup-widdershins', locate_inserter(rotate_inserter_pickup, defines.direction.northwest))

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
    if not get_inserter_prototype(event.destination) then return end

    
    local saved = {
        drop = get_drop_direction(event.destination),
        pickup = get_pickup_direction(event.destination),
        level = get_extension_level(event.destination),
    }

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    storage.saved[event.player_index][event.destination.unit_number] = saved
end)

script.on_event(defines.events.on_entity_settings_pasted, function(event)
    local player = game.get_player(event.player_index)
    if player.mod_settings['yasi-paste-inserter-directions'].value then return end
    if not get_inserter_prototype(event.destination) then return end

    storage.saved = storage.saved or {}
    storage.saved[event.player_index] = storage.saved[event.player_index] or {}
    local saved = storage.saved[event.player_index][event.destination.unit_number]
    storage.saved[event.player_index][event.destination.unit_number] = nil

    if saved then
        set_pickup(event.destination, saved.pickup, saved.level)
        set_drop(event.destination, saved.drop, saved.level)
    end
end)

script.on_event(defines.events.on_player_rotated_entity, function(event)
    local inserter = event.entity
    local prototype = get_inserter_prototype(inserter)
    if not prototype then return end
    local turn = defines.direction.northwest
    if add_direction(event.previous_direction, defines.direction.east) == inserter.direction then
        turn = defines.direction.northeast
    end
    inserter.direction = event.previous_direction
    rotate_inserter(inserter, get_inserter_prototype(inserter), turn)
end)

commands.add_command('yasi-fix-inserters', {'command.yasi-fix-inserters'}, function(command)
    for i = 1, #game.surfaces do
        local surface = game.surfaces[i]

        local inserters = surface.find_entities_filtered{
            type = 'inserter'
        }

        for _, inserter in pairs(inserters) do
            if inserter.valid then
                set_pickup(inserter)
                set_drop(inserter)
            end
        end

        inserters = surface.find_entities_filtered{
            ghost_type = 'inserter'
        }

        for _, inserter in pairs(inserters) do
            if inserter.valid then
                set_pickup(inserter)
                set_drop(inserter)
            end
        end
    end
end)