
local yasilib = {}

local util = require 'util'
local math2d = require 'math2d'

yasilib.number_of_directions = table_size(defines.direction)

if not defines.direction then error("defines.direction not found") end
if not table_size(defines.direction) then error("defines.direction has no table_size") end

function yasilib.add_direction(direction, turn)
    return (direction + turn) % yasilib.number_of_directions
end

function yasilib.ortho_or_diagonal(direction)
    return direction % defines.direction.east
end

function yasilib.dot_product(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end
 
yasilib.pickup_offset = {
    [defines.direction.north] = { 1, 1, 2, 2 },
    [defines.direction.northeast] = { 1.1, 1.1, 2.2, 2.2 },
}

yasilib.drop_offset = {
    [defines.direction.north] = { 0.7, 1.2, 1.7, 2.2 },
    [defines.direction.northeast] = { 0.8, 1.3, 1.8, 2.3 },
}

yasilib.normalised_direction_vectors = {}

for _, dir in pairs{ 'north', 'northeast', 'east', 'southeast', 'south', 'southwest', 'west', 'northwest' } do
    dir = defines.direction[dir]
    yasilib.normalised_direction_vectors[dir] = math2d.position.get_normalised(util.direction_vectors[dir])
end


function yasilib.get_drop_offset(inserter)
    return math2d.position.subtract(inserter.drop_position, inserter.position)
end

function yasilib.get_pickup_offset(inserter)
    return math2d.position.subtract(inserter.pickup_position, inserter.position)
end

function yasilib.vector_to_direction(vector)
    local length = math.sqrt(yasilib.dot_product(vector, vector))
    local min = length - 0.001
    local max = length + 0.001
    for dir, normal in pairs(yasilib.normalised_direction_vectors) do
        local proj = yasilib.dot_product(vector, normal)
        if min < proj and proj < max then return dir end
    end
end

function yasilib.get_pickup_direction(inserter)
    return yasilib.vector_to_direction(yasilib.get_pickup_offset(inserter))
        or inserter.direction
end

function yasilib.get_drop_direction(inserter)
    return yasilib.vector_to_direction(yasilib.get_drop_offset(inserter))
        or util.oppositedirection(inserter.direction)
end


function yasilib.get_extension_level(inserter)
    local offset = yasilib.get_drop_offset(inserter)
    local direction = yasilib.vector_to_direction(offset)
    local distance = math.sqrt(yasilib.dot_product(offset, offset))
    local drops = yasilib.drop_offset[yasilib.ortho_or_diagonal(direction)]
    for i=1, #drops do
        if math.abs(drops[i] - distance) < 0.2 then return i end
    end
    if distance > yasilib.drop_offset[4] then return 4 end
    if distance < yasilib.drop_offset[1] then return 1 end
    return 2
end

function yasilib.get_max_extension_level(prototype)
    local speed = prototype.get_inserter_extension_speed('normal')
    if speed < 0.05 then return 2 else return 4 end
end

function yasilib.set_pickup(inserter, direction, level)
    level = level or yasilib.get_extension_level(inserter)
    direction = direction or yasilib.get_pickup_direction(inserter)
    local offset = math2d.position.multiply_scalar(
        yasilib.normalised_direction_vectors[direction],
        yasilib.pickup_offset[yasilib.ortho_or_diagonal(direction)][level]
    )
    inserter.pickup_position = math2d.position.add(inserter.position, offset)
end

function yasilib.set_drop(inserter, direction, level)
    level = level or yasilib.get_extension_level(inserter)
    direction = direction or yasilib.get_drop_direction(inserter)
    local offset = math2d.position.multiply_scalar(
        yasilib.normalised_direction_vectors[direction],
        yasilib.drop_offset[yasilib.ortho_or_diagonal(direction)][level]
    )
    inserter.drop_position = math2d.position.add(inserter.position, offset)
end

function yasilib.adjust_inserter_extension(adjustment, inserter, prototype)
    if not inserter then return end
    local level = yasilib.get_extension_level(inserter)
    local max = yasilib.get_max_extension_level(prototype)
    next_level = util.clamp(level + adjustment, 1, max)
    yasilib.set_pickup(inserter, nil, next_level)
    yasilib.set_drop(inserter, nil, next_level)
end


function yasilib.rotate_inserter_pickup(turn, inserter, prototype)
    if not inserter then return end
    local new_direction = yasilib.add_direction(yasilib.get_pickup_direction(inserter), turn)
    yasilib.set_pickup(inserter, new_direction, nil)
end

yasilib.cardinals = {
    [defines.direction.north] = true,
    [defines.direction.east] = true,
    [defines.direction.south] = true,
    [defines.direction.west] = true,
}

function yasilib.rotate_inserter(turn, inserter, prototype)
    if not inserter then return end

    local pickup_direction = yasilib.add_direction(yasilib.get_pickup_direction(inserter), turn)
    local drop_direction = yasilib.add_direction(yasilib.get_drop_direction(inserter), turn)

    if yasilib.cardinals[drop_direction] then inserter.direction = util.oppositedirection(drop_direction) end

    yasilib.set_pickup(inserter, pickup_direction, nil)
    yasilib.set_drop(inserter, drop_direction, nil)
end

function yasilib.reset_inserter(inserter, prototype)
    if not inserter then return end
    yasilib.set_pickup(inserter, util.oppositedirection(inserter.direction), 2)
    yasilib.set_drop(inserter, inserter.direction, 2)
end

function yasilib.get_inserter_prototype(inserter)
    if inserter.type == 'inserter' then return inserter.prototype end
    if inserter.type == 'entity-ghost' and inserter.ghost_type == 'inserter' then return inserter.ghost_prototype end
end

function yasilib.locate_inserter(event)
    local player = game.get_player(event.player_index)

    local entity = player.selected

    if not entity then return end

    local prototype = yasilib.get_inserter_prototype(entity)

    if prototype then return entity, prototype end
end

setmetatable(yasilib, {
    __tostring = function() return 'yasilib' end,
    __index = function(_, k) error('no such key yasilib.' .. k) end,
    __newindex = function(_, k) error('no such key yasilib.' .. k) end,
})

return yasilib