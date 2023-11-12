-- Populate database with planes
local function populate_planes()
    for i = 1, 80 do
        local plane_id = tostring(i)
        redis.call("SET", "plane:" .. plane_id, "unassigned")
    end
end

-- Populate database with parking spots
local function populate_parking_spots()
    for i = 1, 99 do
        local spot_id = tostring(i)
        redis.call("SET", "parking_spot:" .. spot_id, "unassigned")
    end
end

-- Check if provided plane_id is within boundaries
local function is_valid_plane_id(plane_id)
    local min_id = 1
    local max_id = 80
    return tonumber(plane_id) and tonumber(plane_id) >= min_id and tonumber(plane_id) <= max_id
end


local function get_unassigned_parking_spots()
    local all_spots = redis.call("KEYS", "parking_spot:*")
    local unassigned_spots = {}

    for _, spot_key in ipairs(all_spots) do
        local spot_value = redis.call("GET", spot_key)
        if spot_value == "unassigned" then
            table.insert(unassigned_spots, spot_key)
        end
    end
    return unassigned_spots
end


local function assign_parking_spot(plane_id)
    local current_parking_spot = redis.call("GET", "plane:" .. plane_id)
    if current_parking_spot == "unassigned" then
        math.randomseed(redis.call("TIME")[1])
        local unassigned_spots = get_unassigned_parking_spots()
        if #unassigned_spots < 1 then
            return "No parking spots available"
        end
        local random_spot = unassigned_spots[math.random(#unassigned_spots)]
        local spot_id = string.match(random_spot, "parking_spot:(%d+)")
        if spot_id == nil then
            return "Error while getting a random free spot"
        end
        redis.call("SET", "plane:" .. plane_id, spot_id)
        redis.call("SET", random_spot, plane_id)
        return "Assigned parking spot " .. spot_id .. " to plane " .. plane_id
    end
    return "Plane " .. plane_id .. " already has a parking spot " .. current_parking_spot
end


if redis.call("EXISTS", "plane:1") == 0 then
    populate_planes()
end
if redis.call("EXISTS", "parking_spot:1") == 0 then
    populate_parking_spots()
end

local plane_id = ARGV[1]
if not is_valid_plane_id(plane_id) then
    return "Invalid plane_id: " .. tostring(plane_id)
end

return assign_parking_spot(plane_id)
