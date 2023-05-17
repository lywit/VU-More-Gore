--- @class RotationHelper
RotationHelper = class 'RotationHelper'

--YPR: yaw, pitch, roll
--LUF: left, up, forward
--LT: LinearTransform

local sin = math.sin
local asin = math.asin
local cos = math.cos
local atan = math.atan
local pi = math.pi
local sqrt = math.sqrt

function RotationHelper:GetYawFromForward(forward)
	local yaw = atan(forward.x, forward.z)

	if yaw < 0 then
		yaw = -yaw
	else
		yaw = 2 * pi - yaw
	end

	return yaw
end

function RotationHelper:GetYPRFromLUF(left, up, forward)
	-- Reference: http://www.jldoty.com/code/DirectX/YPRfromUF/YPRfromUF.html

	-- Special case, forward is (0,1,0) or (0,-1,0)
	if forward.x == 0 and forward.z == 0 then
		local yaw = 0
		local pitch = forward.y * pi/2
		local roll = asin(-up.x)

		return yaw, pitch, roll
	end

	local pitch = asin(forward.y)

	local yaw = atan(forward.x, forward.z)
	local roll = 0

	local y = Vec3(0,1,0)

	-- r0 is the right vector before pitch rotation
	local r0 = Vec3(0,0,0)
	local r1 = y:Cross(forward)

	-- Normalizing r0
	local mod_r1 = sqrt(r1.x^2 + r1.y^2 + r1.z^2)

	r0.x = r1.x / mod_r1
	r0.y = r1.y / mod_r1
	r0.z = r1.z / mod_r1

	-- u0 is the up vector before pitch rotation
	local u0 = forward:Cross(r0)

	local cosPitch = u0:Dot(up)

	if r0.x > r0.y and r0.x > r0.z and r0.x ~= 0 then
		roll = asin( (u0.x * cosPitch - up.x) / r0.x)
	elseif r0.y > r0.x and r0.y > r0.z and r0.y ~= 0 then
		roll = asin( (u0.y * cosPitch - up.y) / r0.y)
	elseif r0.z > r0.x and r0.z > r0.y and r0.z ~= 0 then
		roll = asin( (u0.z * cosPitch - up.z) / r0.z)
	else
		if r0.x ~= 0 then
			roll = asin( (u0.x * cosPitch - up.x) / r0.x)
		elseif r0.y ~= 0 then
			roll = asin( (u0.y * cosPitch - up.y) / r0.y)
		elseif r0.z ~= 0 then
			roll = asin( (u0.z * cosPitch - up.z) / r0.z)
		else
			print("[RotationHelper] All denominators are 0, something went wrong")
		end
	end

	-- Update ranges:
	-- yaw: (0, 2pi), clockwise, north = 0
	-- pitch: (-pi, pi), horizon = 0, straight up = pi/2
	-- roll: (-pi/2, pi/2), horizon = 0, full roll right = pi/2

	if yaw < 0 then
		yaw = -yaw
	else
		yaw = 2 * pi - yaw
	end

	if up.y < 0 then
		roll = -roll

		if pitch < 0 then
			pitch = (pitch + pi) * -1
		else
			pitch = pi - pitch
		end

		if yaw < pi then
			yaw = yaw + pi
		else
			yaw = yaw - pi
		end
	end

	return yaw, pitch, roll
end

function RotationHelper:GetLUFFromYPR(yaw, pitch, roll)
	-- Reference: http://planning.cs.uiuc.edu/node102.html


	local fx = -sin(yaw) * cos(pitch)
	local fy = sin(pitch)
	local fz = cos(yaw) * cos(pitch)

	local forward = Vec3(fx, fy, fz)

	local lx = sin(yaw) * sin(pitch) * sin(roll) + cos(yaw) * cos(roll)
	local ly = cos(pitch) * sin(roll)
	local lz = -cos(yaw) * sin(pitch) * sin(roll) + sin(yaw) * cos(roll)

	local left = Vec3(lx, ly, lz)

	local up = left:Cross(forward) * -1

	return left, up, forward
end

--------------Linear Transform variants-------
function RotationHelper:GetYPRFromLT(linearTransform)
	if linearTransform.typeInfo.name == nil or linearTransform.typeInfo.name ~= "LinearTransform" then
		print("[RotationHelper] Wrong argument for GetYPRFromLT, expected LinearTransform")

		return
	end

	local yaw, pitch, roll = self:GetYPRFromLUF(
		linearTransform.left,
		linearTransform.up,
		linearTransform.forward
	)

	return yaw, pitch, roll
end

function RotationHelper:GetLTFromYPR(yaw, pitch, roll)
	local left, up, forward = self:GetLUFFromYPR(yaw, pitch, roll)

	return LinearTransform(left, up, forward, Vec3(0,0,0))
end


-------------Util--------------------
function RotationHelper:AdjustRange(vIn, offset, rightLimit)
	local v = vIn
	v = v + offset
	if (v > rightLimit) then
		v = v - rightLimit
	end
	if (v < 0) then
	v = v + rightLimit;
	end
	return v
end

return RotationHelper
