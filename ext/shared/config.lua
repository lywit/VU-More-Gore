--Blood
bloodOnEveryHit = true --Spawns networked blood effects on every bullet based on damage
damagePerBloodEffect = 7 --Damage required to spawn an extra blood effect. Blood effect amount will be: damage / damagePerBloodEffect
damagePerEffectHeadshotFactor = 0.175
maxBloodEffectsPerHit = 1 --Maximum amount of blood effects can be spawned per hit
maxBloodEffectsPerFrame = 8
splashRayLength = 6

--Blood Pool
bloodPoolSizeMultiplier = 2.25 --Size of the blood pool effect on dead bodies
bloodPoolSizeRandomness = 0.75 --The randomness that will be added to the blood pool effect's size
bloodPoolRayLength = 3

--Blood Splattter
maxBloodSplatterAmount = 4096  --The maximum amount of blood effects that can be spawned
bloodSplatterLifetimeMultiplier = 1.15 --How long new blood splatters should be spawned
bloodSplatterSpawnRateMultiplier = 1.15 --How fast new blood splatters should be spawned
bloodSplatterSizeMultiplier = 0.7 --The spawn area size for blood splatters
bloodSplatterEffectDistanceMultiplier = 1 --The distance where blood splatters will be rendered

--Corpses
--Note that for Fun-Bots to be effected you need to set AdditionalBotSpawnDelay in the Config to the desired corpse time for bots. Otherwise their corpses will disappear in 0.5 seconds by Fun-Bots default.
corpseDecayTime = 60 --The time in seconds it takes for a player's body to despawn | Default = 15 | Note: Keep in mind that a server will crash if over 512 bodies are on the ground at once

--Dismemberment
--Multipliers | Higher values make it easier to dismember a body part.
headMultiplier = 2.00
armMultiplier = 4.00 --Note that arms can be difficult to hit
legMultiplier = 4.00 --Note that leg hitboxes are difficult to hit (You have to shoot at the feet)
--Settings
enableDismemberment = true --Set to false to disable dismembered
dismemberArmsBeforeDeath = false --Arms can be dismembered before death, intended for zombie servers. Otherwise bots will hold floating guns.
dismembermentBloodSquirtDegredationFactor = 1.1 --How quickly the blood squirt frequency degrades. Higher values cause blood squirts to dissapear sooner.
dismembermentBloodSquirtSizeReductionFactor = 0.975 -- How quickly blood squirts reduce in size. Lower values make the size reduce faster.
bloodSquirtSpawnInterval = 4 --Updater interval for spawning blood squirts. Lower values spawns squirts faster.

--Vehicles
enableVehicleModifications = true --enable or disable vehicle modifications
vehicleCorpseDecayTime = 900.0 --The time in seconds it takes for vehicle wrecks to despawn | Default = 60
vehicleWreckHealthMultiplier = 3 --Multiplies the health of vehicle wrecks

--Trees
enableTreeModifications = true
treeCorpseTime = 1800 -- The time before destroyed trees despawn | Default = 30

--Debris
enableDebrisModifications = false --enable or disable debris modifications
debrisDecayTime = 128 --The time it takes for debris to decay, this effects every type of debris in the game
debrisMaxCount = 256 --The maximum debris per part.
debrisIsClientSide = true --This will make it so every debris part has it's physics calulated on the client instead of some parts being calulated on the server.
						  --With these physics being made client sided, it could be that other players won't see the debris in the exact same place or see floating debris. You can consider enabling this to increase server fps at the cost of consistency.
killPartsOnCollision = false --This prevents debris from being despawned when it falls on the ground
deactiveOnSleep = true --This is an optimization that disables the debris physics after the debris has been sitting still on the ground for some time