
local yasilib = {}

local util = require 'util'
local math2d = require 'math2d'

yasilib.number_of_directions = table_size(defines.direction)

if not defines.direction then error("defines.direction not found") end
if not table_size(defines.direction) then error("defines.direction has no table_size") end

function yasilib.add_direction(direction, turn)
    return (direction + turn) % yasilib.number_of_directions
end

function yasilib.is_orthogonal(direction)
    return direction % defines.direction.east == 0
end

function yasilib.dot_product(v1, v2)
    return v1.x * v2.x + v1.y * v2.y
end
 
yasilib.pickup_distances = {
    orthogonal = { 1, 1, 2, 2 },
    diagonal = { 1.1, 1.1, 2.2, 2.2 },
}

yasilib.dropoff_distances = {
    orthogonal = { 0.7, 1.2, 1.7, 2.2 },
    diagonal = { 0.8, 1.3, 1.9, 2.4 },
}

yasilib.normalised_direction_vectors = {}

for _, dir in pairs{ 'north', 'northeast', 'east', 'southeast', 'south', 'southwest', 'west', 'northwest' } do
    dir = defines.direction[dir]
    yasilib.normalised_direction_vectors[dir] = math2d.position.get_normalised(util.direction_vectors[dir])
end

yasilib.direction_names = { }
for i=1,31 do yasilib.direction_names[i] = '' end
for name, direction in pairs(defines.direction) do
    yasilib.direction_names[direction] = name
end


function yasilib.get_drop_offset(inserter)
    return math2d.position.subtract(inserter.drop_position, inserter.position)
end

function yasilib.get_pickup_offset(inserter)
    return math2d.position.subtract(inserter.pickup_position, inserter.position)
end

local exsin_22_5 = 1 - math.sin(3 * math.pi / 8)

function yasilib.vector_to_direction(vector)
    local length = math.sqrt(yasilib.dot_product(vector, vector))
    local min = length - exsin_22_5
    local max = length + 0.01
    for dir, normal in pairs(yasilib.normalised_direction_vectors) do
        local proj = yasilib.dot_product(vector, normal)
        if min < proj and proj < max then return dir end
    end
end

function yasilib.get_pickup_direction(inserter)
    return yasilib.vector_to_direction(yasilib.get_pickup_offset(inserter))
        or inserter.direction
end

function yasilib.get_dropoff_direction(inserter)
    return yasilib.vector_to_direction(yasilib.get_drop_offset(inserter))
        or util.oppositedirection(inserter.direction)
end

function yasilib.arg_min_diff(number, points)
    for i=1, #points-1 do
        local mid = (points[i+1] - points[i]) / 2 + points[i]
        if number < mid then return i end
    end
    return #points
end


function yasilib.get_extension_level(inserter)
    local offset = yasilib.get_drop_offset(inserter)
    local direction = yasilib.vector_to_direction(offset)
    local distance = math.sqrt(yasilib.dot_product(offset, offset))
    
    if yasilib.is_orthogonal(direction) then
        return yasilib.arg_min_diff(distance, yasilib.dropoff_distances.orthogonal)
    else
        return yasilib.arg_min_diff(distance, yasilib.dropoff_distances.orthogonal)
    end
end

local memo = {}
function yasilib.get_max_extension_level(inserter)
    if memo[inserter.name] then return memo[inserter.name] end
    local speed = inserter.prototype.get_inserter_extension_speed('normal')
    if speed < 0.05 then
        memo[inserter.name] = 2
        return 2
    else
        memo[inserter.name] = 4
        return 4
    end
end

function yasilib.offset_from_direction_level(direction, level, distances)
    return math2d.position.multiply_scalar(
        yasilib.normalised_direction_vectors[direction],
        yasilib.is_orthogonal(direction) and distances.orthogonal[level] or distances.diagonal[level]
    )
end

function yasilib.set_pickup_dropoff(inserter, pickup_direction, dropoff_direction, level)
    if level == nil then
        level = yasilib.get_extension_level(inserter)
    end
    if level == nil then error() end

    pickup_direction = pickup_direction or yasilib.get_pickup_direction(inserter)
    dropoff_direction = dropoff_direction or yasilib.get_dropoff_direction(inserter)
    
    level = util.clamp(level, 1, yasilib.get_max_extension_level(inserter))

    pickup_direction = pickup_direction - pickup_direction % 2
    local pickup = yasilib.offset_from_direction_level(pickup_direction, level, yasilib.pickup_distances)
    inserter.pickup_position = math2d.position.add(inserter.position, pickup)

    dropoff_direction = dropoff_direction - dropoff_direction % 2
    local dropoff = yasilib.offset_from_direction_level(dropoff_direction, level, yasilib.dropoff_distances)
    inserter.drop_position = math2d.position.add(inserter.position, dropoff)
end

function yasilib.adjust_inserter_extension(inserter, adjustment)
    if not inserter then return end
    local level = yasilib.get_extension_level(inserter)
    yasilib.set_pickup_dropoff(inserter, nil, nil, level + adjustment)
end

function yasilib.rotate_inserter_pickup(inserter, turn)
    if not inserter then return end
    local pickup = yasilib.add_direction(yasilib.get_pickup_direction(inserter), turn)
    yasilib.set_pickup_dropoff(inserter, pickup, nil, nil)
end


yasilib.cardinals = {
    [defines.direction.north] = true,
    [defines.direction.east] = true,
    [defines.direction.south] = true,
    [defines.direction.west] = true,
}

function yasilib.rotate_inserter(inserter, turn)
    if not inserter then return end
    local pickup = yasilib.add_direction(yasilib.get_pickup_direction(inserter), turn)
    local dropoff = yasilib.add_direction(yasilib.get_dropoff_direction(inserter), turn)
    if yasilib.cardinals[dropoff] then inserter.direction = util.oppositedirection(dropoff) end
    yasilib.set_pickup_dropoff(inserter, pickup, dropoff, nil)
end

function yasilib.reset_inserter(inserter)
    if not inserter then return end
    yasilib.set_pickup_dropoff(inserter, inserter.direction, utils.oppositedirection(inserter.direction), 2)
end

function yasilib.is_inserter(inserter)
    return inserter and (inserter.type == 'inserter' or inserter.type == 'entity-ghost' and inserter.ghost_type == 'inserter')
end

function yasilib.locate_inserter(event)
    local player = game.get_player(event.player_index)
    if yasilib.is_inserter(player.selected) then return player.selected end
end

setmetatable(yasilib, {
    __tostring = function() return 'yasilib' end,
    __index = function(_, k) error('no such key yasilib.' .. k) end,
    __newindex = function(_, k) error('no such key yasilib.' .. k) end,
})

return yasilib