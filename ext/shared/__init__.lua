--Corpses
local corpseDecayTime = 45 --The time in seconds it takes for a player's body to despawn | Default = 15 | Note: Keep in mind that a server will crash if over 512 bodies are on the ground

--Vehicles
local vehicleCorpseDecayTime = 60.0 --The time in seconds it takes for vehicle wrecks to despawn | Default = 60

--Debris
local debrisDecayTime = 60 --The time it takes for debris to decay, this effects every type of debris in the game
local debrisMaxCount = 64 --The maximum debris per part.
local debrisIsClientSide = true --This will make it so every debris part has it's physics calulated on the client instead of some parts being calulated on the server.
								 --With these physics being made client sided, it could be that other players won't see the debris in the exact same place or see floating debris. You can consider enabling this to increase server fps at the cost of consistency.
local killPartsOnCollision = false --This prevents debris from being despawned when it falls on the ground
local deactiveOnSleep = true --This is an optimization that disables the debris physics after the debris has been sitting still on the ground for some time


Events:Subscribe('Partition:Loaded', function(partition)

	local instances = partition.instances

	for _, instance in pairs(instances) do

		if(instance:Is('BangerEntityData')) then

			local bangerData = BangerEntityData(instance)

			if(string.find(tostring(bangerData.mesh.name), 'vehicles/')) and string.find(tostring(bangerData.mesh.name), 'wreck') then
				bangerData:MakeWritable()
				bangerData.timeToLive = vehicleCorpseDecayTime
			end
		elseif(instance:Is('DebrisClusterData')) then
			local debrisData = DebrisClusterData(instance)
			debrisData:MakeWritable()

			debrisData.clusterLifetime = debrisDecayTime
			debrisData.maxActivePartsCount = debrisMaxCount

			--These if statements are done this way to allow the values to be restored to the vanilla ones
			if(debrisIsClientSide == true) then
				debrisData.clientSideOnly = true
			end

			if(killPartsOnCollision == false) then
				debrisData.killPartsOnCollision = false
			end

			if(deactiveOnSleep == true) then
				debrisData.deactivatePartsOnSleep = true
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