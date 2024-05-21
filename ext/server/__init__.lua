--Credit to Ensio for his version checking code!
require('__shared/version')
require('__shared/Util/Functions')

local currDeltaTime = 0

Events:Subscribe('Player:Update', function(player, deltaTime)
    currDeltaTime = deltaTime
end)

Hooks:Install('Soldier:Damage', 1, function(hook, soldier, info, giverInfo)
    if not soldier or not soldier.player or not enableDismemberment then
        return
    elseif giverInfo.giver and giverInfo.giver.teamId == soldier.player.teamId then
        -- Prevent friendly fire from causing dismemberment
        return
    end

    local boneIndex = info.boneIndex
    local playerName = soldier.player.name
    local position = info.position
    local eventData = string.format("%s,%d,%f,%f,%f,%f", playerName, boneIndex, position.x, position.y, position.z, info.damage)

    if info.isBulletDamage then
        local enoughDamage = DoesEnoughDamageToDismember(info.damage, boneIndex, soldier.maxHealth)
        if (info.damage > soldier.health and enoughDamage) or
           ((boneIndex == 2 or boneIndex == 3) and enoughDamage and dismemberArmsBeforeDeath) then
            NetEvents:Broadcast('DismembermentEvent', eventData)
        end
    elseif (info.isExplosiveDamage or info.isDemolitionDamage) and info.damage > soldier.health then
        for _ = 1, MathUtils:GetRandomInt(1, 3) do
            local randomBoneIndex = MathUtils:GetRandomInt(2, 5)
            local randomEventData = string.format("%s,%d,%f,%f,%f,%f", playerName, randomBoneIndex, position.x, position.y, position.z, info.damage)
            NetEvents:Broadcast('DismembermentEvent', randomEventData)
        end
    end
end)


Hooks:Install('BulletEntity:Collision', 1, function(hook, entity, hit, giverInfo)
    if hit.bone ~= -1 and hit.part == 4294967295 and giverInfo.giver.soldier then
        local distanceToGiverPos = 0.15
        local hitPos = hit.position
        local giverPos = giverInfo.giver.soldier.worldTransform.trans
        
        local direction = Vec3(hitPos.x - giverPos.x, hitPos.y - giverPos.y, hitPos.z - giverPos.z):Normalize()

        -- Update hitPos by moving it closer to giverPos
        hitPos.x = hitPos.x - (direction.x * distanceToGiverPos)
        hitPos.z = hitPos.z - (direction.z * distanceToGiverPos)

        -- Format position and direction as strings for broadcasting
        local hitPosStr = string.format('%f,%f,%f', hitPos.x, hitPos.y, hitPos.z)
        local directionStr = string.format('%f,%f,%f', direction.x, direction.y, direction.z)

        NetEvents:BroadcastUnreliableLocal('BloodEffectEvent', hitPosStr .. ',' .. 1 .. ',' .. 0, directionStr)
    end
end)

Events:Subscribe('Soldier:HealthAction', function(soldier, action)
    if action == HealthStateAction.OnRevive then
        NetEvents:Broadcast('RemoveDismemberment', soldier.bus.networkId)
    end
end)

Events:Subscribe('Player:Respawn', function(player)
    if player.soldier then
        NetEvents:Broadcast('RemoveDismemberment', player.soldier.bus.networkId)
    end
end)

Events:Subscribe('Player:SpawnOnPlayer', function(player, playerToSpawnOn)
    if player.soldier then
        NetEvents:Broadcast('RemoveDismemberment', player.soldier.bus.networkId)
    end
end)

Events:Subscribe('Player:ReviveAccepted', function(player, reviver)
    if player.soldier then
        NetEvents:Broadcast('RemoveDismemberment', player.soldier.bus.networkId)
    end
end)

Events:Subscribe('Player:Left', function(player)
    if player.soldier then
        NetEvents:Broadcast('RemoveDismemberment', player.soldier.bus.networkId)
    end
end)

-- In case of same networkId as a soldier who may not exist but is in the dismembered players
Events:Subscribe('Player:Joining', function(name, playerGuid, ipAddress, accountGuid)
    player = PlayerManager:GetPlayerByGuid(playerGuid)
    if player and player.soldier then
        NetEvents:Broadcast('RemoveDismemberment', player.soldier.bus.networkId)
    end
end)

function DoesEnoughDamageToDismember(damage, bone, maxHealth)

    if bone == 1 then
        damage = (damage / 2.4) * headMultiplier
    elseif bone == 2 or bone == 3 then
        damage = damage * armMultiplier
    elseif bone == 4 or bone == 5 then
        damage = damage * legMultiplier
    end


    return MathUtils:GetRandomInt(0, 100) < (damage / maxHealth * 100)
end

function GetCurrentVersion()
    -- Version Check Code Credit: https://gitlab.com/n4gi0s/vu-mapvote by N4gi0s
    options = HttpOptions({}, 10)
    options.verifyCertificate = false
    res = Net:GetHTTP("https://raw.githubusercontent.com/lywit/VU-More-Gore/main/mod.json", options)

    if res.status ~= 200 then
        return null
    end

    json = json.decode(res.body)
    return json.Version

end

function CheckVersion()

    if GetCurrentVersion() ~= localModVersion then

        print("Version: " .. localModVersion)
        print("More Gore is out of date! Download the latest version here: https://github.com/lywit/VU-More-Gore");
        print('Latest version: ' .. json.Version)

    else

        print("Version: " .. localModVersion)
        

    end

end

CheckVersion()