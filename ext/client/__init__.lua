require '__shared/config'

local DismemberedPlayers = {}
local DismemberedPlayerBones = {}
local bloodEffect = nil

NetEvents:Subscribe('DismembermentEvent', function(data)
	data = split_with_comma(data)
	data[2] = ConvertDamageBoneToSkeletonBone(data[2])
	if data[1] ~= nil and data[2] ~= nil then
		--Check for duplicate dismembered bones
		local playerIndex = indexOf(DismemberedPlayers, data[1])
		if playerIndex ~= nil then
			if data[2] == DismemberedPlayerBones[playerIndex] then
				return
			end
		end

		table.insert(DismemberedPlayers, data[1])
		table.insert(DismemberedPlayerBones, data[2])

		if bloodEffect ~= nil and data[3] ~= nil and data[4] ~= nil and data[5] ~= nil then
			local effectPosition = LinearTransform()
			effectPosition.left = Vec3(1, 0, 0)
			effectPosition.up = Vec3(0, 1, 0)
			effectPosition.forward = Vec3(0, 0, 1)
			effectPosition.trans = Vec3(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]))

			EffectManager:PlayEffect(bloodEffect, effectPosition, EffectParams(), false)
		end
	end
end)

NetEvents:Subscribe('RemoveDismemberment', function(data)
	player = PlayerManager:GetPlayerByName(data)
	if player ~= nil then
		RemoveDismemberedPlayer(player.name)
	end
end)

--Thank you for the optimization tip IllustrisJack ;)
Events:Subscribe('UpdateManager:Update', function(deltaTime, updatePass)
    if updatePass == 0 then
		UpdateDismemberment()
	end
end)

Events:Subscribe('Level:Loaded', function(levelName, gameMode)
    DismemberedPlayers = {}
	DismemberedPlayerBones = {}

	bloodEffect = ResourceManager:FindInstanceByGuid(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('245A136F-C690-A293-3806-7973D09D40DB'))
	if bloodEffect == nil then
		print('Blood effect is nil!')
	else
		bloodEffect = EffectBlueprint(bloodEffect)
	end
end)

function UpdateDismemberment()
	for i, p in ipairs(DismemberedPlayers) do
		local player = PlayerManager:GetPlayerByName(tostring(p))
		local dismembermentQuatTransform = nil

		if player and player ~= nil then
			if player.alive == false then
				if not player.corpse or player.corpse == nil then
					RemoveDismemberedPlayer(DismemberedPlayers[i])
				else
					dismembermentQuatTransform = player.corpse.ragdollComponent:GetLocalTransform(tonumber(DismemberedPlayerBones[i]))
					if dismembermentQuatTransform ~= nil then
						dismembermentQuatTransform.transAndScale.w = 0.0
						player.corpse.ragdollComponent:SetLocalTransform(tonumber(DismemberedPlayerBones[i]), dismembermentQuatTransform)
					end
				end
			elseif player.soldier then
				dismembermentQuatTransform = player.soldier.ragdollComponent:GetLocalTransform(tonumber(DismemberedPlayerBones[i]))
				if dismembermentQuatTransform ~= nil then
					dismembermentQuatTransform.transAndScale.w = 0.0
					player.soldier.ragdollComponent:SetLocalTransform(tonumber(DismemberedPlayerBones[i]), dismembermentQuatTransform)
				end
			end
		end
	end
end

function RemoveDismemberedPlayer(player)
	local i = indexOf(DismemberedPlayers, player)
	while i ~= nil do
		table.remove(DismemberedPlayers, i)
		table.remove(DismemberedPlayerBones, i)
		i = indexOf(DismemberedPlayers, player)
	end
end

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

function split_with_comma(str)
	local fields = {}
	for field in str:gmatch('([^,]+)') do
	  fields[#fields+1] = field
	end
	return fields
end

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/Decals/Blood/Decal_Blood_01.txt#L2
ResourceManager:RegisterInstanceLoadHandler(Guid('40065C6B-E2F3-4412-82B2-946461757471'), Guid('E87D1CAE-C080-4D70-AF5E-A504BA52ED5D'), function(instance)
	instance = DecalTemplateData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodPoolSizeMultiplier
	instance.randomSize = bloodPoolSizeRandomness
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/Decals/Blood/Decal_DeathBlood_01.txt#L2
ResourceManager:RegisterInstanceLoadHandler(Guid('DC025293-D649-448C-BC99-D8F47FE12877'), Guid('D0E150D9-7D7C-4BD3-8D03-584B7B221471'), function(instance)
	instance = DecalTemplateData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodPoolSizeMultiplier
	instance.randomSize = bloodPoolSizeRandomness
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L8
ResourceManager:RegisterInstanceLoadHandler(Guid('611A7D99-A4F8-4602-BC40-A5D958200174'), Guid('1EC467CA-0792-43F9-AF7D-21A156881165'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.visibleAfterDistance = instance.visibleAfterDistance * bloodSplatterEffectDistanceMultiplier
	instance.maxSpawnDistance = instance.maxSpawnDistance * bloodSplatterEffectDistanceMultiplier
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L199
ResourceManager:RegisterInstanceLoadHandler(Guid('611A7D99-A4F8-4602-BC40-A5D958200174'), Guid('AFA60DA0-DE32-4619-9215-A9DD834495E4'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L244
ResourceManager:RegisterInstanceLoadHandler(Guid('611A7D99-A4F8-4602-BC40-A5D958200174'), Guid('34345B29-3030-4682-86D0-4F646F6D65B9'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_Chunks_01_S.txt#L36
ResourceManager:RegisterInstanceLoadHandler(Guid('68D37A4B-1A02-4FBC-BB22-DEF26D6CF8A0'), Guid('73888C8A-F1F4-497F-AAD5-AC08AF0D4223'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.visibleAfterDistance = instance.visibleAfterDistance * bloodSplatterEffectDistanceMultiplier
	instance.maxSpawnDistance = instance.maxSpawnDistance * bloodSplatterEffectDistanceMultiplier
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_Chunks_01_S.txt#L287
ResourceManager:RegisterInstanceLoadHandler(Guid('68D37A4B-1A02-4FBC-BB22-DEF26D6CF8A0'), Guid('B9E8F591-9394-4605-B0BC-7EA331556F51'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
