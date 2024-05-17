require '__shared/config'

Events:Subscribe('Partition:Loaded', function(partition)
	for _, instance in pairs(partition.instances) do

		-- if enableVehicleModifications and string.find(tostring(partition.name), 'vehicles/') and string.find(tostring(partition.name), 'wreck') then
		-- 	if(instance:Is('BangerEntityData')) then
		-- 		instance = BangerEntityData(instance)
		-- 		instance:MakeWritable()
		-- 		instance.timeToLive = vehicleCorpseDecayTime
		-- 	elseif instance:Is('HealthComponentData') then
		-- 		instance = HealthComponentData(instance)
		-- 		instance:MakeWritable()
		-- 		instance.health = instance.health * vehicleWreckHealthMultiplier
				
		-- 	elseif instance:Is('HealthStateData') then
		-- 		instance = HealthStateData(instance)
		-- 		instance:MakeWritable()
		-- 		instance.health = instance.health * vehicleWreckHealthMultiplier
		-- 	end
		-- end

		if enableTreeModifications and instance:Is('VegetationTreeEntityData') then
			instance = VegetationTreeEntityData(instance)
			instance:MakeWritable()
			instance.partsTimeToLive = treeCorpseTime
		end
		
		-- if enableDebrisModifications and instance:Is('DebrisClusterData') then
		-- 	instance = DebrisClusterData(instance)
		-- 	instance:MakeWritable()

		-- 	instance.clusterLifetime = debrisDecayTime
		-- 	instance.maxActivePartsCount = debrisMaxCount

		-- 	--These if statements are done this way to allow the values to be restored to the vanilla ones
		-- 	if(debrisIsClientSide == true) then
		-- 		instance.clientSideOnly = true
		-- 	end

		-- 	if(killPartsOnCollision == false) then
		-- 		instance.killPartsOnCollision = false
		-- 	end

		-- 	if(deactiveOnSleep == true) then
		-- 		instance.deactivatePartsOnSleep = true
		-- 	end

		-- end
		
	end
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_Chunks_01_S.txt#L287 
ResourceManager:RegisterInstanceLoadHandler(Guid('F256E142-C9D8-4BFE-985B-3960B9E9D189'), Guid('705967EE-66D3-4440-88B9-FEEF77F53E77'), function(instance)
	instance = VeniceSoldierHealthModuleData(instance)

	instance:MakeWritable()
	instance.timeForCorpse = corpseDecayTime
end)


Events:Subscribe('Level:Destroy', function()
    collectgarbage("collect")
end)