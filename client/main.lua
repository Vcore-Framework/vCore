VCore = {}
VCore.PlayerData = {}
VCore.Config = Config
VCore.Shared = {}
VCore.ClientCallbacks = {}
VCore.ServerCallbacks = {}

-- Player Loaded
RegisterNetEvent('vCore:Client:OnPlayerLoaded', function()
    ShutdownLoadingScreenNrt()
    
    if Config.Player.RevealMap then
        SetMinimapHideFow(true)
    end
    
    VCore.Debug('Player loaded on client')
end)

-- Player Unload
RegisterNetEvent('vCore:Client:OnPlayerUnload', function()
    VCore.PlayerData = {}
end)

-- Update Player Data
RegisterNetEvent('vCore:Player:SetPlayerData', function(data)
    VCore.PlayerData = data
end)

-- Job Update
RegisterNetEvent('vCore:Client:OnJobUpdate', function(job)
    VCore.PlayerData.job = job
    TriggerEvent('vCore:Client:JobUpdate', job)
end)

-- Gang Update
RegisterNetEvent('vCore:Client:OnGangUpdate', function(gang)
    VCore.PlayerData.gang = gang
    TriggerEvent('vCore:Client:GangUpdate', gang)
end)

-- Set Duty
RegisterNetEvent('vCore:Client:SetDuty', function(duty)
    VCore.PlayerData.job.onduty = duty
    TriggerEvent('vCore:Client:DutyUpdate', duty)
end)

-- Money HUD Update
RegisterNetEvent('vCore:Player:UpdatePlayerMoney', function(amount, moneyType, operation, reason)
    local currentAmount = VCore.PlayerData.money[moneyType] or 0
    
    if operation == 'add' then
        VCore.PlayerData.money[moneyType] = currentAmount + amount
    elseif operation == 'remove' then
        VCore.PlayerData.money[moneyType] = currentAmount - amount
    elseif operation == 'set' then
        VCore.PlayerData.money[moneyType] = amount
    end
    
    TriggerEvent('vCore:Client:OnMoneyChange', moneyType, VCore.PlayerData.money[moneyType], operation, reason)
end)

-- Functions
VCore.Functions = {}

VCore.Functions.GetPlayerData = function(cb)
    if not cb then return VCore.PlayerData end
    cb(VCore.PlayerData)
end

VCore.Functions.GetCoords = function(entity)
    local coords = GetEntityCoords(entity or PlayerPedId(), false)
    local heading = GetEntityHeading(entity or PlayerPedId())
    return vector4(coords.x, coords.y, coords.z, heading)
end

VCore.Functions.HasItem = function(item, amount)
    -- This would integrate with your inventory system
    return lib.callback.await('vCore:HasItem', false, item, amount or 1)
end

VCore.Functions.Notify = function(text, notifyType, duration)
    lib.notify({
        description = text,
        type = notifyType or 'inform',
        duration = duration or 5000
    })
end

VCore.Functions.DrawText = function(text, position)
    if position == 'left' then
        lib.showTextUI(text, {position = 'left-center'})
    elseif position == 'right' then
        lib.showTextUI(text, {position = 'right-center'})
    else
        lib.showTextUI(text)
    end
end

VCore.Functions.HideText = function()
    lib.hideTextUI()
end

VCore.Functions.KeyPressed = function()
    CreateThread(function()
        VCore.Functions.Notify('Key pressed!', 'success')
    end)
end

VCore.Functions.SpawnVehicle = function(model, cb, coords, isnetworked, teleportInto)
    local model = type(model) == 'string' and joaat(model) or model
    local coords = coords or VCore.Functions.GetCoords(PlayerPedId())
    local isnetworked = isnetworked or true
    local teleportInto = teleportInto or false
    
    lib.requestModel(model, 10000)
    
    local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, isnetworked, false)
    
    SetModelAsNoLongerNeeded(model)
    
    if teleportInto then
        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    end
    
    if cb then
        cb(veh)
    end
end

VCore.Functions.DeleteVehicle = function(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

VCore.Functions.GetVehicles = function()
    return GetGamePool('CVehicle')
end

VCore.Functions.GetObjects = function()
    return GetGamePool('CObject')
end

VCore.Functions.GetPlayers = function()
    local players = {}
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if DoesEntityExist(ped) then
            players[#players + 1] = player
        end
    end
    return players
end

VCore.Functions.GetPlayersFromCoords = function(coords, distance)
    local players = VCore.Functions.GetPlayers()
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local distance = distance or 5
    local closePlayers = {}
    
    for _, player in pairs(players) do
        local target = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(target)
        local targetdistance = #(targetCoords - coords)
        
        if targetdistance <= distance then
            closePlayers[#closePlayers + 1] = player
        end
    end
    
    return closePlayers
end

VCore.Functions.GetClosestPlayer = function(coords, distance)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local distance = distance or 5
    local closestPlayers = VCore.Functions.GetPlayersFromCoords(coords, distance)
    local closestDistance = -1
    local closestPlayer = -1
    
    for i = 1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local dist = #(pos - coords)
            
            if closestDistance == -1 or closestDistance > dist then
                closestPlayer = closestPlayers[i]
                closestDistance = dist
            end
        end
    end
    
    return closestPlayer, closestDistance
end

VCore.Functions.GetClosestPed = function(coords, ignoreList)
    local ped = PlayerPedId()
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    local ignoreList = ignoreList or {}
    local peds = GetGamePool('CPed')
    local closestPeds = {}
    
    for i = 1, #peds, 1 do
        local pedCoords = GetEntityCoords(peds[i])
        local distance = #(pedCoords - coords)
        local isIgnored = false
        
        for j = 1, #ignoreList, 1 do
            if peds[i] == ignoreList[j] then
                isIgnored = true
            end
        end
        
        if not isIgnored then
            closestPeds[#closestPeds + 1] = {ped = peds[i], distance = distance}
        end
    end
    
    table.sort(closestPeds, function(a, b)
        return a.distance < b.distance
    end)
    
    return closestPeds[1] and closestPeds[1].ped or nil
end

VCore.Functions.GetClosestVehicle = function(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    
    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)
        
        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

VCore.Functions.GetClosestObject = function(coords)
    local ped = PlayerPedId()
    local objects = GetGamePool('CObject')
    local closestDistance = -1
    local closestObject = -1
    
    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end
    
    for i = 1, #objects, 1 do
        local objectCoords = GetEntityCoords(objects[i])
        local distance = #(objectCoords - coords)
        
        if closestDistance == -1 or closestDistance > distance then
            closestObject = objects[i]
            closestDistance = distance
        end
    end
    
    return closestObject, closestDistance
end

VCore.Functions.TriggerCallback = function(name, cb, ...)
    VCore.ServerCallbacks[name] = cb
    TriggerServerEvent('vCore:Server:TriggerCallback', name, ...)
end

VCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    if lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = useWhileDead or false,
        canCancel = canCancel or false,
        disable = disableControls or {
            move = false,
            car = false,
            mouse = false,
            combat = false
        },
        anim = animation,
        prop = prop,
    }) then
        if onFinish then
            onFinish()
        end
    else
        if onCancel then
            onCancel()
        end
    end
end

RegisterNetEvent('vCore:Client:TriggerCallback', function(name, ...)
    if VCore.ServerCallbacks[name] then
        VCore.ServerCallbacks[name](...)
        VCore.ServerCallbacks[name] = nil
    end
end)

-- Initialize
CreateThread(function()
    while true do
        Wait(0)
        
        if NetworkIsPlayerActive(PlayerId()) then
            TriggerServerEvent('vCore:Server:OnPlayerLoaded')
            TriggerEvent('vCore:Client:OnPlayerLoaded')
            break
        end
    end
end)

print('^2[vCore]^7 Client Module Loaded')
print('^2[vCore]^7 Framework Version: ^31.0.0^7')