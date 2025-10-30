VCore.Players = {}
VCore.Player_Buckets = {}
VCore.Entity_Buckets = {}
VCore.UsableItems = {}

-- Initialize Database
CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local success = MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `players` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `cid` int(11) DEFAULT NULL,
            `license` varchar(255) NOT NULL,
            `name` varchar(255) NOT NULL,
            `money` text DEFAULT NULL,
            `charinfo` text DEFAULT NULL,
            `job` text DEFAULT NULL,
            `gang` text DEFAULT NULL,
            `position` text DEFAULT NULL,
            `metadata` text DEFAULT NULL,
            `inventory` longtext DEFAULT NULL,
            `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
            PRIMARY KEY (`citizenid`),
            KEY `id` (`id`),
            KEY `last_updated` (`last_updated`),
            KEY `license` (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    
    if success then
        print('^2[vCore]^7 Database tables verified/created successfully')
    end
end)

-- Get Player
VCore.Functions = {}

VCore.Functions.GetPlayer = function(source)
    if type(source) == 'number' then
        return VCore.Players[source]
    else
        return VCore.Players[VCore.Functions.GetSource(source)]
    end
end

VCore.Functions.GetPlayerByCitizenId = function(citizenid)
    for src, player in pairs(VCore.Players) do
        if player.PlayerData.citizenid == citizenid then
            return player
        end
    end
    return nil
end

VCore.Functions.GetPlayers = function()
    local sources = {}
    for k in pairs(VCore.Players) do
        sources[#sources + 1] = k
    end
    return sources
end

VCore.Functions.GetSource = function(identifier)
    for src, player in pairs(VCore.Players) do
        local idens = GetPlayerIdentifiers(src)
        for _, id in pairs(idens) do
            if identifier == id then
                return src
            end
        end
    end
    return 0
end

VCore.Functions.GetPermission = function(source)
    local src = source
    local Player = VCore.Functions.GetPlayer(src)
    local permission = 'user'
    
    if IsPlayerAceAllowed(src, 'vcore.god') then
        permission = 'god'
    elseif IsPlayerAceAllowed(src, 'vcore.admin') then
        permission = 'admin'
    elseif IsPlayerAceAllowed(src, 'vcore.mod') then
        permission = 'mod'
    end
    
    return permission
end

VCore.Functions.HasPermission = function(source, permission)
    local src = source
    local playerPermission = VCore.Functions.GetPermission(src)
    
    if playerPermission == 'god' then
        return true
    elseif playerPermission == 'admin' and (permission == 'admin' or permission == 'mod') then
        return true
    elseif playerPermission == 'mod' and permission == 'mod' then
        return true
    end
    
    return false
end

VCore.Functions.IsOptin = function(source)
    local src = source
    local Player = VCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.PlayerData.optin
end

VCore.Functions.ToggleOptin = function(source)
    local src = source
    local Player = VCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.PlayerData.optin = not Player.PlayerData.optin
    Player.Functions.Save()
end

VCore.Functions.IsPlayerBanned = function(license)
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM bans WHERE license = ? AND expire > NOW()', {license})
    return result > 0
end

VCore.Functions.Notify = function(source, text, notifyType, duration)
    TriggerClientEvent('ox_lib:notify', source, {
        description = text,
        type = notifyType or 'inform',
        duration = duration or 5000
    })
end

VCore.Functions.CreateCallback = function(name, cb)
    VCore.ServerCallbacks[name] = cb
end

VCore.Functions.TriggerCallback = function(name, source, cb, ...)
    if not VCore.ServerCallbacks[name] then return end
    VCore.ServerCallbacks[name](source, cb, ...)
end

VCore.Functions.CreateUseableItem = function(item, cb)
    VCore.UsableItems[item] = cb
end

VCore.Functions.CanUseItem = function(item)
    return VCore.UsableItems[item] ~= nil
end

VCore.Functions.UseItem = function(source, item)
    if VCore.UsableItems[item] then
        VCore.UsableItems[item](source, item)
    end
end

VCore.Functions.Kick = function(source, reason, setKickReason, deferrals)
    reason = reason or 'You have been kicked from the server'
    setKickReason = setKickReason or reason
    
    if deferrals then
        deferrals.update(setKickReason)
        Wait(2500)
        deferrals.done(setKickReason)
    else
        DropPlayer(source, setKickReason)
    end
end

-- Player Connecting
AddEventHandler('playerConnecting', function(name, _, deferrals)
    local src = source
    local license
    local identifiers = GetPlayerIdentifiers(src)
    deferrals.defer()
    
    Wait(0)
    
    deferrals.update('Checking identifiers...')
    
    for _, v in pairs(identifiers) do
        if string.find(v, 'license') then
            license = v
            break
        end
    end
    
    if not license then
        VCore.Functions.Kick(src, 'No valid Rockstar license found', 'No valid Rockstar license found', deferrals)
        return
    end
    
    deferrals.update('Checking ban status...')
    
    if VCore.Functions.IsPlayerBanned(license) then
        VCore.Functions.Kick(src, 'You are banned from this server', 'You are banned from this server', deferrals)
        return
    end
    
    deferrals.done()
end)

-- Player Joined
RegisterNetEvent('vCore:Server:OnPlayerLoaded', function()
    local src = source
    local Player = VCore.Functions.GetPlayer(src)
    if not Player then return end
    
    VCore.Debug('Player loaded:', GetPlayerName(src))
end)

-- Player Dropping
AddEventHandler('playerDropped', function(reason)
    local src = source
    local Player = VCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    VCore.Debug('Player dropped:', GetPlayerName(src), 'Reason:', reason)
    
    Player.Functions.Save()
    VCore.Player_Buckets[Player.PlayerData.source] = nil
    VCore.Players[src] = nil
end)

-- Resource Start/Stop
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        VCore.Debug('vCore Framework started')
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for k in pairs(VCore.Players) do
            local Player = VCore.Functions.GetPlayer(k)
            if Player then
                Player.Functions.Save()
            end
        end
        VCore.Debug('vCore Framework stopped - All players saved')
    end
end)

RegisterNetEvent('vCore:CallbackClient', function(name, ...)
    if VCore.ClientCallbacks[name] then
        VCore.ClientCallbacks[name](...)
    end
end)

print('^2[vCore]^7 Server Module Loaded')
print('^2[vCore]^7 Framework Version: ^31.0.0^7')