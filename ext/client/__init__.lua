require '__shared/config'


local DismemberedPlayers = {}
local DismemberedPlayerBones = {}
local DismemberedPlayerBonesSquirtChance = {}
local DismemberedPlayerBonesSquirtSize = {}
local bloodEffect = nil
local bloodSquirtUpdateCount = 0


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
		local p = PlayerManager:GetPlayerByName(data[1])
		if p == nil then return end

		table.insert(DismemberedPlayers, PlayerManager:GetPlayerByName(data[1]).id)
		table.insert(DismemberedPlayerBones, data[2])
		table.insert(DismemberedPlayerBonesSquirtChance, 0.01)
		table.insert(DismemberedPlayerBonesSquirtSize, MathUtils:GetRandom(0.75, 1.25))

		if bloodEffect ~= nil and data[3] ~= nil and data[4] ~= nil and data[5] ~= nil then
			local lTransform = LinearTransform()
			lTransform.trans = Vec3(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]))
			SpawnBloodEffect(lTransform, data[6], data[2] == 45)
		end
	end
end)

function RemoveDismemberedPlayer(player)
	local i = indexOf(DismemberedPlayers, player)
	while i ~= nil do
		table.remove(DismemberedPlayers, i)
		table.remove(DismemberedPlayerBones, i)
		table.remove(DismemberedPlayerBonesSquirtChance, i)
		table.remove(DismemberedPlayerBonesSquirtSize, i)
		i = indexOf(DismemberedPlayers, player)
	end
end

NetEvents:Subscribe('BloodEffectEvent', function(data)
	data = split_with_comma(data)
	if bloodEffect ~= nil and data[1] ~= nil and data[2] ~= nil and data[3] ~= nil and data[4] ~= nil then
		local lTransform = LinearTransform()
		lTransform.trans = Vec3(tonumber(data[1]), tonumber(data[2]), tonumber(data[3]))
		SpawnBloodEffect(lTransform, data[4], data[5] == 1)
	end
end)

NetEvents:Subscribe('RemoveDismemberment', function(data)
	player = PlayerManager:GetPlayerById(tonumber(data))
	if player ~= nil then
		RemoveDismemberedPlayer(player.id)
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
	DismemberedPlayerBonesSquirtChance = {}
	DismemberedPlayerBonesSquirtSize = {}

	bloodEffect = EffectBlueprint(ResourceManager:FindInstanceByGuid(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('245A136F-C690-A293-3806-7973D09D40DB')))
	if bloodEffect == nil then
		print('bloodEffect is nil!')
	end
end)

function UpdateDismemberment()
	local updateBloodSquirts = false
	if bloodSquirtUpdateCount > bloodSquirtSpawnInterval then
		updateBloodSquirts = true
		bloodSquirtUpdateCount = 0
	end

	for i, p in ipairs(DismemberedPlayers) do
		local player = PlayerManager:GetPlayerById(p)
		local dismembermentQuatTransform = nil
		local worldQuatTransform = nil
		local ragdoll = nil

		if player and player ~= nil then
			if player.alive == false then
				if not player.corpse or player.corpse == nil then
					RemoveDismemberedPlayer(DismemberedPlayers[i])
				else
					ragdoll = player.corpse.ragdollComponent
				end
			elseif player.soldier then
				ragdoll = player.soldier.ragdollComponent
			end
			if ragdoll ~= nil then
				if updateBloodSquirts == true then
					worldQuatTransform = ragdoll:GetActiveWorldTransform(DismemberedPlayerBones[i])
					if worldQuatTransform ~= nil then
						if player.alive == false and MathUtils:GetRandom(0, DismemberedPlayerBonesSquirtChance[i]) < 1 then
							DismemberedPlayerBonesSquirtSize[i] = DismemberedPlayerBonesSquirtSize[i] * dismembermentBloodSquirtSizeReductionFactor
							DismemberedPlayerBonesSquirtChance[i] = DismemberedPlayerBonesSquirtChance[i] * dismembermentBloodSquirtDegredationFactor
							SpawnBloodEffect(worldQuatTransform:ToLinearTransform(), 0, false, DismemberedPlayerBonesSquirtSize[i])
						elseif player.alive == true then
							SpawnBloodEffect(worldQuatTransform:ToLinearTransform(), 0, false, DismemberedPlayerBonesSquirtSize[i])
						end
					end
				end

				dismembermentQuatTransform = ragdoll:GetLocalTransform(DismemberedPlayerBones[i])
				if dismembermentQuatTransform ~= nil then
					dismembermentQuatTransform.transAndScale.w = 0.0
					ragdoll:SetLocalTransform(DismemberedPlayerBones[i], dismembermentQuatTransform)
				end
			end
		end
	end
	bloodSquirtUpdateCount = bloodSquirtUpdateCount + 1
end

function SpawnBloodEffect(position, damage, isHeadshot, sizeOverwrite)
	if bloodEffect ~= nil and position ~= nil then
		local effectPosition = LinearTransform()
		local effectSize = 0

		damage = tonumber(damage)
		if isHeadshot then
			damage = damage / 2.4
		end

		if sizeOverwrite == nil then
			if damage ~= nil then
				effectSize =  (1.0 + (damage / 100)) * MathUtils:GetRandom(0.75, 1.25)
			else
				effectSize = 1
			end
		else
			effectSize = sizeOverwrite
		end

		effectPosition.left = Vec3(effectSize, position.left.y, position.left.z)
		effectPosition.up = Vec3(position.up.x, effectSize, position.up.z)
		effectPosition.forward = Vec3(position.forward.x, position.forward.y, effectSize)
		effectPosition.trans = position.trans

		EffectManager:PlayEffect(bloodEffect, effectPosition, EffectParams(), false)
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

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/Characters/Soldiers/MpSoldier.txt#LL5315C27-L5315C27
ResourceManager:RegisterInstanceLoadHandler(Guid('F256E142-C9D8-4BFE-985B-3960B9E9D189'), Guid('EE531A1F-417F-4F53-BE2B-F555945EA3E7'), function(instance)
	instance = SoldierDecalComponentData(instance)

	instance:MakeWritable()
	instance.splashRayLength = bulletBloodSplatterDistance
	instance.poolRayLength = bloodPoolDistance
end)

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
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L8
ResourceManager:RegisterInstanceLoadHandler(Guid('CF10F423-478C-47CC-9BFB-8E16B9B1F187'), Guid('96726978-5BCE-4745-B24B-4AF0F5F368A1'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L199
ResourceManager:RegisterInstanceLoadHandler(Guid('611A7D99-A4F8-4602-BC40-A5D958200174'), Guid('AFA60DA0-DE32-4619-9215-A9DD834495E4'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('611A7D99-A4F8-4602-BC40-A5D958200174'), Guid('34345B29-3030-4682-86D0-4F646F6D65B9'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('68D37A4B-1A02-4FBC-BB22-DEF26D6CF8A0'), Guid('73888C8A-F1F4-497F-AAD5-AC08AF0D4223'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('68D37A4B-1A02-4FBC-BB22-DEF26D6CF8A0'), Guid('B9E8F591-9394-4605-B0BC-7EA331556F51'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Particle_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('91CFF1D3-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('9B507034-08F7-4EF0-9802-7AC69D91DC3B'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('91CFF1D3-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('80522CB2-BF30-0529-0AD5-0C5559DC979B'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('91CFF1D3-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('0EE3D168-5B41-4BA0-A318-C30ED5CE06CD'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_SmokeGray_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('F080EB5F-BC10-47FC-BD95-2499A52B5ACE'), Guid('B78F2B05-2CBD-4FDA-8338-9D9717B074A1'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('F080EB5F-BC10-47FC-BD95-2499A52B5ACE'), Guid('B4CB355D-1A6D-4BA5-9AEA-19933ED3ED61'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('F080EB5F-BC10-47FC-BD95-2499A52B5ACE'), Guid('BDABBD04-59E3-4552-9C97-5107C1DBCE3B'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Splat_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('CF10F423-478C-47CC-9BFB-8E16B9B1F187'), Guid('D49F9213-F4C0-4080-8925-D0069BF7FC88'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('CF10F423-478C-47CC-9BFB-8E16B9B1F187'), Guid('96726978-5BCE-4745-B24B-4AF0F5F368A1'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('CF10F423-478C-47CC-9BFB-8E16B9B1F187'), Guid('AF71CE59-9DA1-4F54-BA65-38FBDC92CAFC'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_BloodSmoke_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('04A6AAC6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('1C2157A8-A302-4AFB-93CF-E0FB372E15BF'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('04A6AAC6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('1A43459E-C77D-A0B3-44A5-CA076BC1F478'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('04A6AAC6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('FE2E91E6-6F21-4352-A679-D3D005AD75C7'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_BloodSmoke_02_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('8096D617-FECC-478D-AAED-31949BFD790F'), Guid('E75381D5-55D2-49EE-A6D1-43688E06BB46'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('8096D617-FECC-478D-AAED-31949BFD790F'), Guid('445BE235-A657-400F-91B0-86F3CFEC6DDC'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('8096D617-FECC-478D-AAED-31949BFD790F'), Guid('CB66C431-2994-4124-8965-CB21E86063CE'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_Blood_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('0D39B5F6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('71D8FF21-73E3-4E6C-9A8F-F3387FA950CD'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('0D39B5F6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('BFDEA1E0-14C9-898B-64F2-FC5C2FE38769'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('0D39B5F6-46E7-11DE-9F79-8FE6EED9BBEA'), Guid('E13AD8D4-72A1-4413-824B-3060BF523609'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_Blood_Chunks_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('DA1EF1C7-B797-41F5-8622-03036202F94C'), Guid('936833D4-CB0A-4870-BA97-2906A1BCA598'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('DA1EF1C7-B797-41F5-8622-03036202F94C'), Guid('DEB61774-F601-4E2A-B141-F3909DD1C317'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('DA1EF1C7-B797-41F5-8622-03036202F94C'), Guid('EFD0D486-B848-4B9C-9CEF-33D53C13AD17'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_Particle_01_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('FF3D43E3-CFBA-4D4A-B313-74194B1AE894'), Guid('B50CDA15-FB7F-4803-B3BC-9B5B147FB236'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = instance.size * bloodSplatterSizeMultiplier
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('FF3D43E3-CFBA-4D4A-B313-74194B1AE894'), Guid('9E210002-379E-4DB8-AA55-647B982E84A3'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('FF3D43E3-CFBA-4D4A-B313-74194B1AE894'), Guid('40F00F8A-3760-40B2-8617-BA84328C7AAF'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * bloodSplatterSpawnRateMultiplier
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------
ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('CBC0488D-26B7-4D3C-92A6-3D64367B6E24'), function(instance)
	instance = EffectEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)


ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('CBC0488D-26B7-4D3C-92A6-3D64367B6E24'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('F416BFA0-C90C-4627-A13C-F018C4787BDE'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('07FC48D8-4796-4336-97E2-8AF38AF3DC2A'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('0F37073C-1C2C-4898-8480-7E3FF77BE55E'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('7C62FFDD-55DF-40FA-A975-D946C18F71E1'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('D0EF8FB1-DD8C-4A9D-A77E-2C7854A4A5FE'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('D0EF8FB1-DD8C-4A9D-A77E-2C7854A4A5FE'), function(instance)
	instance = EmitterEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 1024
end)