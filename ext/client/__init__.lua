require '__shared/config'
require '__shared/Util/Functions'

local RotationHelper = require '__shared/Util/RotationHelper'

local DismemberedSoldierIDs = {}
local DismemberedSoldiers = {}
local DismemberedPlayers = {}
local DismemberedPlayerBones = {}
local DismemberedPlayerBonesSquirtChance = {}
local DismemberedPlayerBonesSquirtSize = {}
local bloodEffect = nil
local bloodSquirtUpdateCount = 0


NetEvents:Subscribe('DismembermentEvent', function(data)
	data = split_with_comma(data)
	local playerName = data[1]
	local boneIndex = ConvertDamageBoneToSkeletonBone(data[2])
	if playerName ~= nil and boneIndex ~= nil then
		-- Check for duplicate dismembered bones
		local playerIndex = indexOf(DismemberedPlayers, playerName)
		if playerIndex ~= nil then
			if boneIndex == DismemberedPlayerBones[playerIndex] then
				return
			end
		end
		local player = PlayerManager:GetPlayerByName(playerName)
		if player == nil then return end

		if not player.alive then
			if player.corpse then
				table.insert(DismemberedSoldiers, player.corpse)
				table.insert(DismemberedSoldierIDs, player.corpse.bus.networkId)
			end
		elseif player.soldier then
			table.insert(DismemberedSoldiers, player.soldier)
			table.insert(DismemberedSoldierIDs, player.soldier.bus.networkId)
		else
			return
		end

		
		table.insert(DismemberedPlayers, #DismemberedPlayers + 1)
		table.insert(DismemberedPlayerBones, boneIndex)
		table.insert(DismemberedPlayerBonesSquirtChance, 0.01)
		table.insert(DismemberedPlayerBonesSquirtSize, MathUtils:GetRandom(0.75, 1.25))

		if bloodEffect ~= nil and data[3] ~= nil and data[4] ~= nil and data[5] ~= nil then
			local lTransform = LinearTransform()
			lTransform.trans = Vec3(tonumber(data[3]), tonumber(data[4]), tonumber(data[5]))
			SpawnBloodEffect(lTransform, data[6], boneIndex == 45)
		end
	end
end)

function RemoveDismemberedPlayer(id)
	local i = indexOf(DismemberedSoldierIDs, id)
	while i ~= nil do
		table.remove(DismemberedSoldierIDs, i)
		table.remove(DismemberedSoldiers, i)
		table.remove(DismemberedPlayers, i)
		table.remove(DismemberedPlayerBones, i)
		table.remove(DismemberedPlayerBonesSquirtChance, i)
		table.remove(DismemberedPlayerBonesSquirtSize, i)
		i = indexOf(DismemberedSoldierIDs, id)
	end
end

NetEvents:Subscribe('RemoveDismemberment', function(data)
	RemoveDismemberedPlayer(data)
end)

NetEvents:Subscribe('BloodEffectEvent', function(data)
	data = split_with(data, ',')
	if bloodEffect ~= nil and #data >= 4 then
		local lTransform = LinearTransform()
		lTransform.trans = Vec3(tonumber(data[1]), tonumber(data[2]), tonumber(data[3]))
		if #data >= 8 then
			local direction = RotationHelper:GetLTFromYPR(tonumber(data[6]), tonumber(data[7]), tonumber(data[8]))
			lTransform = lTransform * direction
		end

		local damage = tonumber(data[4])
		if tonumber(data[5]) == 1 then
			damage = damage * damagePerEffectHeadshotFactor
		end

		if damage then
			local bloodEffectAmount = MathUtils:Clamp(damage / damagePerBloodEffect, 1, maxBloodEffectsPerHit)
			for i = 1, bloodEffectAmount, 1 do
				SpawnBloodEffect(lTransform, damage)
			end
		end
	end
end)

--Thank you for the optimization tip IllustrisJack ;)
Events:Subscribe('UpdateManager:Update', function(deltaTime, updatePass)
    if updatePass == 0 then
		UpdateDismemberment()
	end
end)

Events:Subscribe('Level:Loaded', function(levelName, gameMode)
	DismemberedSoldierIDs = {}
	DismemberedSoldiers = {}
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
	local updateBloodSquirts = bloodSquirtUpdateCount > bloodSquirtSpawnInterval
	if updateBloodSquirts then
		bloodSquirtUpdateCount = 0
	end

	for i in ipairs(DismemberedPlayers) do
		local player = DismemberedSoldiers[i]
		local ragdoll = nil

		local function checkRagdollComponent()
			return player.ragdollComponent ~= nil
		end
		
		local success, result = pcall(checkRagdollComponent)
		
		if success and result then
			if player.ragdollComponent ~= nil then
				ragdoll = player.ragdollComponent
			end

			if ragdoll then
				local boneIndex = DismemberedPlayerBones[i]
				if updateBloodSquirts then
					local worldQuatTransform = ragdoll:GetActiveWorldTransform(boneIndex)
					if worldQuatTransform and (MathUtils:GetRandom(0, DismemberedPlayerBonesSquirtChance[i]) < 1) then
						DismemberedPlayerBonesSquirtSize[i] = DismemberedPlayerBonesSquirtSize[i] * dismembermentBloodSquirtSizeReductionFactor
						DismemberedPlayerBonesSquirtChance[i] = DismemberedPlayerBonesSquirtChance[i] * dismembermentBloodSquirtDegredationFactor
						SpawnBloodEffect(worldQuatTransform:ToLinearTransform(), 0, false, DismemberedPlayerBonesSquirtSize[i])
					end
				end

				local dismembermentQuatTransform = ragdoll:GetLocalTransform(boneIndex)
				if dismembermentQuatTransform then
					dismembermentQuatTransform.transAndScale.w = 0.0
					ragdoll:SetLocalTransform(boneIndex, dismembermentQuatTransform)
				end
			end
		else
			RemoveDismemberedPlayer(DismemberedSoldierIDs[i])
		end
	end
	bloodSquirtUpdateCount = bloodSquirtUpdateCount + 1
end

function SpawnBloodEffect(position, damage, isHeadshot, sizeOverwrite)
	if bloodEffect and position then
		local effectPosition = LinearTransform()
		local effectSize = sizeOverwrite or ((1.0 + (damage / 100)) * MathUtils:GetRandom(0.75, 1.25))

		if isHeadshot then
			damage = damage / 2.4
		end

		effectPosition.left = Vec3(effectSize, position.left.y, position.left.z)
		effectPosition.up = Vec3(position.up.x, effectSize, position.up.z)
		effectPosition.forward = Vec3(position.forward.x, position.forward.y, effectSize)
		effectPosition.trans = position.trans

		EffectManager:PlayEffect(bloodEffect, effectPosition, EffectParams(), false)
	end
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
	instance.splashRayLength = splashRayLength
	instance.poolRayLength = bloodPoolRayLength
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
	instance.lifetime = instance.lifetime * 0.75
	instance.maxCount = maxBloodSplatterAmount
	instance.forceNiceSorting = true
	instance.transparencySunShadowEnable = true
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_01_S.txt#L8
ResourceManager:RegisterInstanceLoadHandler(Guid('CF10F423-478C-47CC-9BFB-8E16B9B1F187'), Guid('96726978-5BCE-4745-B24B-4AF0F5F368A1'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance:MakeWritable()
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier -- good
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
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier --good
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
	instance.lifetime = instance.lifetime
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
	instance.size = 0 --bad
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('F080EB5F-BC10-47FC-BD95-2499A52B5ACE'), Guid('B4CB355D-1A6D-4BA5-9AEA-19933ED3ED61'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = 0 --bad
	instance.maxCount = maxBloodSplatterAmount
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('F080EB5F-BC10-47FC-BD95-2499A52B5ACE'), Guid('BDABBD04-59E3-4552-9C97-5107C1DBCE3B'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = 0
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_SmokeGray_02_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('0017B8CD-4C74-495D-A386-32E52AA85E13'), Guid('F561FE61-B918-4540-999C-0B8B1EF81A16'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = 0 --bad
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('0017B8CD-4C74-495D-A386-32E52AA85E13'), Guid('D7A12A41-FDAD-4D08-8175-0215CE4E9D19'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = 0 --bad
	instance.maxCount = maxBloodSplatterAmount
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('0017B8CD-4C74-495D-A386-32E52AA85E13'), Guid('D2F82378-64E3-4AB4-A79A-A3EAE9863F84'), function(instance)
	instance = SpawnRateData(instance)

	instance:MakeWritable()
	instance.spawnRate = instance.spawnRate * 0
end)
----------------------------------------------------------------------------------------------------------------------------------------------------------

--https://github.com/VeniceUnleashed/Venice-EBX/blob/1b48533a42f9fce794b52b72e9e8bd33541e6b35/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Head_SmokeGray_02_S.txt
ResourceManager:RegisterInstanceLoadHandler(Guid('0E38330C-77DF-4FCD-A420-587B1E1CF2AA'), Guid('DCA33DB9-4E3D-4BF4-B30B-455B157EF1A6'), function(instance)
	instance = SpawnSizeData(instance)

	instance:MakeWritable()
	instance.size = 0 --bad
end)

ResourceManager:RegisterInstanceLoadHandler(Guid('0E38330C-77DF-4FCD-A420-587B1E1CF2AA'), Guid('D3EC73EF-25B7-4326-8B86-845620212332'), function(instance)
	instance = EmitterTemplateData(instance)

	instance:MakeWritable()
	instance.lifetime = 0 --bad
	instance.maxCount = maxBloodSplatterAmount
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
	instance.lifetime = instance.lifetime * bloodSplatterLifetimeMultiplier --good
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

ResourceManager:RegisterInstanceLoadHandler(Guid('06EE8223-46E0-11DE-9F79-8FE6EED9BBEA'), Guid('D5B66D3A-EA54-9EF1-8D79-C508CDA6F8FA'), function(instance)
	instance = EffectEntityData(instance)

	instance:MakeWritable()
	instance.maxInstanceCount = 4096
	print("Set max blood instances to: " .. instance.maxInstanceCount)
end)