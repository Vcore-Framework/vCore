-- Server Callbacks System
RegisterNetEvent('vCore:Server:TriggerCallback', function(name, ...)
    local src = source
    
    if VCore.ServerCallbacks[name] then
        VCore.ServerCallbacks[name](src, function(...)
            TriggerClientEvent('vCore:Client:TriggerCallback', src, name, ...)
        end, ...)
    end
end)

-- Default Callbacks
VCore.Functions.CreateCallback('vCore:GetPlayerData', function(source, cb)
    local Player = VCore.Functions.GetPlayer(source)
    cb(Player and Player.PlayerData or nil)
end)

VCore.Functions.CreateCallback('vCore:GetPlayers', function(source, cb)
    local players = {}
    
    for k, v in pairs(VCore.Players) do
        players[#players + 1] = VCore.Players[k].PlayerData
    end
    
    cb(players)
end)

VCore.Functions.CreateCallback('vCore:GetPlayer', function(source, cb, playerId)
    local Player = VCore.Functions.GetPlayer(tonumber(playerId))
    cb(Player and Player.PlayerData or nil)
end)

VCore.Functions.CreateCallback('vCore:GetPlayerByCitizenId', function(source, cb, citizenid)
    local Player = VCore.Functions.GetPlayerByCitizenId(citizenid)
    cb(Player and Player.PlayerData or nil)
end)

VCore.Functions.CreateCallback('vCore:HasMoney', function(source, cb, moneytype, amount)
    local Player = VCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(false)
        return
    end
    
    local currentAmount = Player.Functions.GetMoney(moneytype)
    cb(currentAmount >= amount)
end)

VCore.Functions.CreateCallback('vCore:Server:GetCurrentPlayers', function(source, cb)
    cb(#GetPlayers())
end)

VCore.Functions.CreateCallback('vCore:Server:GetMaxPlayers', function(source, cb)
    cb(Config.MaxPlayers)
end)

VCore.Functions.CreateCallback('vCore:Server:GetTotalVehicles', function(source, cb)
    local vehicles = GetAllVehicles()
    cb(#vehicles)
end)

VCore.Functions.CreateCallback('vCore:Server:GetTotalObjects', function(source, cb)
    local objects = GetAllObjects()
    cb(#objects)
end)

VCore.Functions.CreateCallback('vCore:Server:Spawn', function(source, cb, model, coords, warp)
    local ped = GetPlayerPed(source)
    local model = type(model) == 'string' and joaat(model) or model
    
    cb(true)
end)

VCore.Functions.CreateCallback('vCore:HasItem', function(source, cb, item, amount)
    local Player = VCore.Functions.GetPlayer(source)
    
    if not Player then
        cb(false)
        return
    end
    
    -- This should integrate with your inventory system
    -- For now, returning false as placeholder
    cb(false)
end)

VCore.Functions.CreateCallback('vCore:Server:GetConfig', function(source, cb)
    cb(Config)
end)

VCore.Functions.CreateCallback('vCore:Server:GetJobs', function(source, cb)
    cb(Config.Jobs)
end)

VCore.Functions.CreateCallback('vCore:Server:GetGangs', function(source, cb)
    cb(Config.Gangs)
end)

print('^2[vCore]^7 Callbacks Module Loaded')