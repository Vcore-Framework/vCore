-- ┌─────────────────────────────────────────────────────────┐
-- │ ESX Bridge - Client Side                                │
-- │ Makes vCore compatible with ESX resources                │
-- └─────────────────────────────────────────────────────────┘

if not Config.Bridge.EnableLegacySupport then return end

ESX = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false
ESX.UI = {}

-- Get ESX Object
function ESX.GetPlayerData()
    return ESX.PlayerData
end

-- Player Loaded
RegisterNetEvent('vCore:Client:OnPlayerLoaded', function()
    local playerData = VCore.Functions.GetPlayerData()
    
    ESX.PlayerData = {
        identifier = playerData.identifier,
        accounts = {
            {name = 'money', money = playerData.currencies.cash or 0, label = 'Cash'},
            {name = 'bank', money = playerData.currencies.bank or 0, label = 'Bank'},
            {name = 'black_money', money = playerData.currencies.crypto or 0, label = 'Black Money'},
        },
        inventory = playerData.inventory or {},
        job = {
            name = playerData.profession?.name or 'unemployed',
            label = playerData.profession?.label or 'Unemployed',
            grade = playerData.profession?.level or 0,
            grade_name = playerData.profession?.rank or 'Employee',
            grade_label = playerData.profession?.rank or 'Employee',
            grade_salary = playerData.profession?.salary or 0,
        },
        money = playerData.currencies.cash or 0,
        name = playerData.firstName .. ' ' .. playerData.lastName,
        firstname = playerData.firstName,
        lastname = playerData.lastName,
        dateofbirth = playerData.dob,
        sex = playerData.sex,
        height = playerData.height or 180,
        dead = playerData.isDead or false,
        coords = playerData.position or vector3(0, 0, 0),
        maxWeight = playerData.maxWeight or 30000,
    }
    
    ESX.PlayerLoaded = true
    TriggerEvent('esx:playerLoaded', ESX.PlayerData)
end)

RegisterNetEvent('vCore:Client:OnPlayerUnload', function()
    ESX.PlayerData = {}
    ESX.PlayerLoaded = false
end)

-- Update PlayerData
RegisterNetEvent('vCore:Player:SetPlayerData', function(data)
    ESX.PlayerData = {
        identifier = data.identifier,
        accounts = {
            {name = 'money', money = data.currencies.cash or 0, label = 'Cash'},
            {name = 'bank', money = data.currencies.bank or 0, label = 'Bank'},
            {name = 'black_money', money = data.currencies.crypto or 0, label = 'Black Money'},
        },
        inventory = data.inventory or {},
        job = {
            name = data.profession?.name or 'unemployed',
            label = data.profession?.label or 'Unemployed',
            grade = data.profession?.level or 0,
            grade_name = data.profession?.rank or 'Employee',
            grade_label = data.profession?.rank or 'Employee',
            grade_salary = data.profession?.salary or 0,
        },
        money = data.currencies.cash or 0,
        name = data.firstName .. ' ' .. data.lastName,
        firstname = data.firstName,
        lastname = data.lastName,
        dateofbirth = data.dob,
        sex = data.sex,
        height = data.height or 180,
        dead = data.isDead or false,
        coords = data.position or vector3(0, 0, 0),
        maxWeight = data.maxWeight or 30000,
    }
end)

-- Job Update
RegisterNetEvent('vCore:Client:OnProfessionUpdate', function(profession)
    ESX.PlayerData.job = {
        name = profession.name,
        label = profession.label,
        grade = profession.level,
        grade_name = profession.rank,
        grade_label = profession.rank,
        grade_salary = profession.salary,
    }
    TriggerEvent('esx:setJob', ESX.PlayerData.job)
end)

-- Server Callbacks
function ESX.TriggerServerCallback(name, cb, ...)
    VCore.Functions.TriggerCallback(name, cb, ...)
end

-- UI Functions
function ESX.ShowNotification(msg, notifyType, length)
    VCore.Functions.Notify(msg, notifyType or 'inform', length or 5000)
end

function ESX.ShowAdvancedNotification(title, subject, msg, icon, iconType)
    VCore.Functions.Notify(msg, iconType or 'inform', 5000)
end

function ESX.ShowHelpNotification(msg)
    VCore.Functions.DrawText(msg)
    Wait(3000)
    VCore.Functions.HideText()
end

-- UI Elements
ESX.UI.ShowInventoryItemNotification = function(add, item, count)
    local action = add and 'received' or 'removed'
    local itemLabel = VCore.Shared.GetItem(item)?.label or item
    VCore.Functions.Notify('You ' .. action .. ' ' .. count .. 'x ' .. itemLabel, add and 'success' or 'error', 3000)
end

-- Game Functions
ESX.Game = {}

ESX.Game.GetPlayers = function(coords, maxDistance, includePlayerId)
    return VCore.Functions.GetPlayersFromCoords(coords, maxDistance)
end

ESX.Game.GetClosestPlayer = function(coords, maxDistance)
    local closestPlayer, closestDistance = VCore.Functions.GetClosestPlayer(coords, maxDistance)
    return closestPlayer, closestDistance
end

ESX.Game.GetClosestVehicle = function(coords)
    local closestVehicle, closestDistance = VCore.Functions.GetClosestVehicle(coords)
    return closestVehicle, closestDistance
end

ESX.Game.GetClosestObject = function(coords)
    local closestObject, closestDistance = VCore.Functions.GetClosestObject(coords)
    return closestObject, closestDistance
end

ESX.Game.GetVehiclesInArea = function(coords, maxDistance)
    local vehicles = VCore.Functions.GetVehicles()
    local vehiclesInArea = {}
    
    for _, vehicle in pairs(vehicles) do
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance <= maxDistance then
            table.insert(vehiclesInArea, vehicle)
        end
    end
    
    return vehiclesInArea
end

ESX.Game.IsSpawnPointClear = function(coords, maxDistance)
    local vehicles = ESX.Game.GetVehiclesInArea(coords, maxDistance)
    return #vehicles == 0
end

ESX.Game.SpawnVehicle = function(modelName, coords, heading, cb)
    VCore.Functions.SpawnVehicle(modelName, function(vehicle)
        SetEntityHeading(vehicle, heading)
        if cb then cb(vehicle) end
    end, coords, true, false)
end

ESX.Game.SpawnObject = function(modelName, coords, cb)
    local model = type(modelName) == 'string' and joaat(modelName) or modelName
    
    lib.requestModel(model, 10000)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)
    SetModelAsNoLongerNeeded(model)
    
    if cb then cb(obj) end
end

ESX.Game.SpawnLocalObject = function(modelName, coords, cb)
    local model = type(modelName) == 'string' and joaat(modelName) or modelName
    
    lib.requestModel(model, 10000)
    local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
    SetModelAsNoLongerNeeded(model)
    
    if cb then cb(obj) end
end

ESX.Game.DeleteVehicle = function(vehicle)
    VCore.Functions.DeleteVehicle(vehicle)
end

ESX.Game.DeleteObject = function(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

ESX.Game.Teleport = function(entity, coords, cb)
    if not coords.w then
        coords = vector4(coords.x, coords.y, coords.z, 0.0)
    end
    
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    
    while not HasCollisionLoadedAroundEntity(entity) do
        Wait(0)
    end
    
    SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(entity, coords.w)
    
    if cb then cb() end
end

ESX.Game.Utils = {}

ESX.Game.Utils.DrawText3D = function(coords, text, size)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoords()
    local distance = #(camCoords - coords)
    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

-- Streaming
ESX.Streaming = {}

ESX.Streaming.RequestModel = function(modelHash, cb)
    lib.requestModel(modelHash, 10000)
    if cb then cb() end
end

ESX.Streaming.RequestStreamedTextureDict = function(textureDict, cb)
    RequestStreamedTextureDict(textureDict, true)
    while not HasStreamedTextureDictLoaded(textureDict) do
        Wait(0)
    end
    if cb then cb() end
end

ESX.Streaming.RequestNamedPtfxAsset = function(assetName, cb)
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(0)
    end
    if cb then cb() end
end

ESX.Streaming.RequestAnimDict = function(animDict, cb)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
    if cb then cb() end
end

ESX.Streaming.RequestAnimSet = function(animSet, cb)
    RequestAnimSet(animSet)
    while not HasAnimSetLoaded(animSet) do
        Wait(0)
    end
    if cb then cb() end
end

ESX.Streaming.RequestWeaponAsset = function(weaponHash, cb)
    RequestWeaponAsset(weaponHash)
    while not HasWeaponAssetLoaded(weaponHash) do
        Wait(0)
    end
    if cb then cb() end
end

-- Export ESX object
exports('getSharedObject', function()
    return ESX
end)

-- Legacy support
if Config.Bridge.EnableLegacySupport then
    _G.ESX = ESX
end

print('^2[vCore Bridge]^7 ESX client compatibility layer loaded')