require '__shared/config'

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
