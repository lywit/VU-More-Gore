--Corpses
local corpseDecayTime = 120 --The time in seconds it takes for a player's body to despawn | Default = 15 | Note: Keep in mind that a server will crash if over 512 bodies are on the ground
local vehicleCorpseDecayTime = 300.0 --The time in seconds it takes for vehicle wrecks to despawn | Default = 60

Events:Subscribe('Partition:Loaded', function(partition)

	local instances = partition.instances

	for _, instance in pairs(instances) do

		if(instance:Is('BangerEntityData')) then

			local bangerData = BangerEntityData(instance)

			if(string.find(tostring(bangerData.mesh.name), 'vehicles/')) and string.find(tostring(bangerData.mesh.name), 'wreck') then
				bangerData:MakeWritable()
				bangerData.timeToLive = vehicleCorpseDecayTime
			end
		end
	end
end)

--https://github.com/EmulatorNexus/Venice-EBX/blob/f06c290fa43c80e07985eda65ba74c59f4c01aa0/FX/Impacts/Soldier/Emitter_S/Em_Impact_Soldier_Body_Blood_Chunks_01_S.txt#L287 
ResourceManager:RegisterInstanceLoadHandler(Guid('F256E142-C9D8-4BFE-985B-3960B9E9D189'), Guid('705967EE-66D3-4440-88B9-FEEF77F53E77'), function(instance)
	local veniceSoldier = VeniceSoldierHealthModuleData(instance)
	
	veniceSoldier:MakeWritable()
	veniceSoldier.timeForCorpse = corpseDecayTime
	
end)