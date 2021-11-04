--Blood Pool
bloodPoolSizeMultiplier = 2.25 --Size of the blood pool effect on dead bodies
bloodPoolSizeRandomness = 0.75 --The randomness that will be added to the blood pool effect's size

--Blood Splattter
maxBloodSplatterAmount = 128  --The maximum amount of blood effects that can be spawned
bloodSplatterLifetimeMultiplier = 2.25 --How long new blood splatters should be spawned
bloodSplatterSpawnRateMultiplier = 3.75 --How fast new blood splatters should be spawned
bloodSplatterSizeMultiplier = 1.25 --The spawn area size for blood splatters
bloodSplatterEffectDistanceMultiplier = 5.0 --The distance where blood splatters will be rendered

--Corpses
corpseDecayTime = 45 --The time in seconds it takes for a player's body to despawn | Default = 15 | Note: Keep in mind that a server will crash if over 512 bodies are on the ground at once

--Vehicles
enableVehicleModifications = false --enable or disable vehicle modifications
vehicleCorpseDecayTime = 900.0 --The time in seconds it takes for vehicle wrecks to despawn | Default = 60
vehicleWreckHealthMultiplier = 3 --Multiplies the health of vehicle wrecks

--Debris
enableDebrisModifications = false --enable or disable debris modifications
debrisDecayTime = 128 --The time it takes for debris to decay, this effects every type of debris in the game
debrisMaxCount = 256 --The maximum debris per part.
debrisIsClientSide = true --This will make it so every debris part has it's physics calulated on the client instead of some parts being calulated on the server.
						  --With these physics being made client sided, it could be that other players won't see the debris in the exact same place or see floating debris. You can consider enabling this to increase server fps at the cost of consistency.
killPartsOnCollision = false --This prevents debris from being despawned when it falls on the ground
deactiveOnSleep = true --This is an optimization that disables the debris physics after the debris has been sitting still on the ground for some time