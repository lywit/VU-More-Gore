--Credit to Ensio for his version checking code!
require('__shared/version')

local bloodEffect = nil

Hooks:Install('Soldier:Damage', 1, function(hook, soldier, info, giverInfo)
    if soldier == nil or soldier.player == nil or enableDismemberment == false then
        return
    elseif giverInfo.giver ~= nil and giverInfo.giver.teamId == soldier.player.teamId then --prevent friendly fire from causing dismemberment
        return
    end

    local boneIndex = info.boneIndex

    if info.isBulletDamage == true then
        if(((info.damage > soldier.health and DoesEnoughDamageToDismember(info.damage, boneIndex, soldier.maxHealth)) or ((boneIndex == 2 or boneIndex == 3) and DoesEnoughDamageToDismember(info.damage, boneIndex, soldier.maxHealth) and dismemberArmsBeforeDeath == true))) then
            NetEvents:Broadcast('DismembermentEvent', tostring(soldier.player.name) .. ',' .. boneIndex .. ',' .. info.position.x  .. ',' .. info.position.y .. ',' .. info.position.z)
        end
    elseif (info.isExplosiveDamage == true or info.isDemolitionDamage) and info.damage > soldier.health then
        for i = 1, MathUtils:GetRandomInt(1, 3), 1 do
            boneIndex = MathUtils:GetRandomInt(2, 5)
            NetEvents:Broadcast('DismembermentEvent', tostring(soldier.player.name) .. ',' .. boneIndex)
        end
    end

end)

Events:Subscribe('Player:Respawn', function(player)
    if player ~= nil then
        NetEvents:Broadcast('RemoveDismemberment', tostring(player.name))
    end
end)

Events:Subscribe('Player:ReviveAccepted', function(player)
    if player ~= nil then
        NetEvents:Broadcast('RemoveDismemberment', tostring(player.name))
    end
end)

Events:Subscribe('Player:Left', function(player)
    if player ~= nil then
        NetEvents:Broadcast('RemoveDismemberment', tostring(player.name))
    end
end)


function DoesEnoughDamageToDismember(damage, bone, maxHealth)
    local chance = 0

    if bone == 1 then
        damage = (damage / 2.4) * headMultiplier
    elseif bone == 2 or bone == 3 then
        damage = damage * armMultiplier
    elseif bone == 4 or bone == 5 then
        damage = damage * legMultiplier
    end

    chance = damage / maxHealth * 100


    if MathUtils:GetRandomInt(0, 100) < chance then
        return true
    else
        return false
    end
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