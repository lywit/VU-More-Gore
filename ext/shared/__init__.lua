require '__shared/config'

Events:Subscribe('Partition:Loaded', function(partition)
	for _, instance in pairs(partition.instances) do

		if enableVehicleModifications and string.find(tostring(partition.name), 'vehicles/') and string.find(tostring(partition.name), 'wreck') then
			if(instance:Is('BangerEntityData')) then
				instance = BangerEntityData(instance)
				instance:MakeWritable()
				instance.timeToLive = vehicleCorpseDecayTime
			elseif instance:Is('HealthComponentData') then
				instance = HealthComponentData(instance)
				instance:MakeWritable()
				instance.health = instance.health * vehicleWreckHealthMultiplier
				
			elseif instance:Is('HealthStateData') then
				instance = HealthStateData(instance)
				instance:MakeWritable()
				instance.health = instance.health * vehicleWreckHealthMultiplier
			end
		end

		if enableTreeModifications then
			if instance:Is('VegetationTreeEntityData') then
				instance = VegetationTreeEntityData(instance)
				instance:MakeWritable()
				instance.partsTimeToLive = treeCorpseTime
			end
		end
		
		if enableDebrisModifications and instance:Is('DebrisClusterData') then
			instance = DebrisClusterData(instance)
			instance:MakeWritable()

			instance.clusterLifetime = debrisDecayTime
			instance.maxActivePartsCount = debrisMaxCount

			--These if statements are done this way to allow the values to be restored to the vanilla ones
			if(debrisIsClientSide == true) then
				instance.clientSideOnly = true
			end

			if(killPartsOnCollision == false) then
				instance.killPartsOnCollision = false
			end

			if(deactiveOnSleep == true) then
				instance.deactivatePartsOnSleep = true
			end

		end
		
	end
end)

Events:Subscribe('Level:Destroy', function()
    collectgarbage("collect")
end)