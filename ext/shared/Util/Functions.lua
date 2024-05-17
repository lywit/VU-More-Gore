
function ConvertDamageBoneToSkeletonBone(bone)
	bone = tonumber(bone)
	if bone == 0 then
		return nil
	elseif bone == 1 then -- head
		return 45
	elseif bone == 2 then --right arm
		return 121
	elseif bone == 3 then --left arm
		return 9
	elseif bone == 4 then --right leg
		return 198
	elseif bone == 5 then --left leg
		return 183
	elseif bone == 6 then --Spine
		return 6
	else
		return nil
	end
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
	for _, v in pairs(list) do
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