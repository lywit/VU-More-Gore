local boneMap = {
    [0] = nil,
    [1] = 45,  -- head
    [2] = 121, -- right arm
    [3] = 9,   -- left arm
    [4] = 198, -- right leg
    [5] = 183, -- left leg
    [6] = 6    -- spine
}

function ConvertDamageBoneToSkeletonBone(bone)
    return boneMap[tonumber(bone)]
end

function indexOf(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end

function contains(list, x)
    if list == nil then return false end
    for _, v in ipairs(list) do
        if v == x then return true end
    end
    return false
end

function split_with(str, seperator, numeric)
	numeric = numeric or false
	if str == nil then return nil end
	local fields = {}
	for field in str:gmatch('([^' .. seperator .. ']+)') do
		if numeric then field = tonumber(field) end
		fields[#fields+1] = field
	end
	return fields
end

function getDistance(a, b)
    local x, y, z = a.x-b.x, a.y-b.y, a.z-b.z;
    return math.sqrt(x*x+y*y+z*z);
end