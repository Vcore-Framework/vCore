-- ┌─────────────────────────────────────────────────────────┐
-- │ QBCore Bridge - Client Side                             │
-- │ Makes vCore compatible with QBCore resources            │
-- └─────────────────────────────────────────────────────────┘

if not Config.Bridge.EnableLegacySupport then return end

QBCore = {}
QBCore.PlayerData = {}
QBCore.Config = Config
QBCore.Shared = {}
QBCore.Functions = {}

-- Get Core Object
local function GetCoreObject()
    return QBCore
end

-- Player Data Update
RegisterNetEvent('vCore:Client:OnPlayerLoaded', function()
    local playerData = VCore.Functions.GetPlayerData()
    local currencies = playerData.currencies or {} -- Add this line
    
    QBCore.PlayerData = {
        citizenid = playerData.citizenid,
        license = playerData.identifier,
        name = (playerData.firstName or '') .. ' ' .. (playerData.lastName or ''),
        money = {
            cash = currencies.cash or 0,    -- Changed from playerData.currencies.cash
            bank = currencies.bank or 0,    -- Changed from playerData.currencies.bank
            crypto = currencies.crypto or 0, -- Changed from playerData.currencies.crypto
        },
        charinfo = {
            firstname = playerData.firstName,
            lastname = playerData.lastName,
            birthdate = playerData.dob,
            gender = playerData.sex,
        },
        job = {
            name = playerData.profession?.name or 'unemployed',
            label = playerData.profession?.label or 'Unemployed',
            payment = playerData.profession?.salary or 0,
            onduty = playerData.profession?.onDuty or false,
            isboss = playerData.profession?.isBoss or false,
            grade = {
                name = playerData.profession?.rank or 'Freelancer',
                level = playerData.profession?.level or 0,
            }
        },
        gang = {
            name = playerData.organization?.name or 'none',
            label = playerData.organization?.label or 'No Gang',
            isboss = playerData.organization?.isLeader or false,
            grade = {
                name = playerData.organization?.rank or 'Member',
                level = playerData.organization?.level or 0,
            }
        },
        metadata = {
            hunger = playerData.status?.hunger or 100,
            thirst = playerData.status?.thirst or 100,
            stress = playerData.status?.stress or 0,
            isdead = playerData.isDead or false,
        },
        items = playerData.inventory or {},
    }
    
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

RegisterNetEvent('vCore:Client:OnPlayerUnload', function()
    QBCore.PlayerData = {}
    TriggerEvent('QBCore:Client:OnPlayerUnload')
end)

-- Update PlayerData when vCore updates
RegisterNetEvent('vCore:Player:SetPlayerData', function(data)
    QBCore.PlayerData = {
        citizenid = data.citizenid,
        license = data.identifier,
        name = data.firstName .. ' ' .. data.lastName,
        money = {
            cash = data.currencies.cash or 0,
            bank = data.currencies.bank or 0,
            crypto = data.currencies.crypto or 0,
        },
        charinfo = {
            firstname = data.firstName,
            lastname = data.lastName,
            birthdate = data.dob,
            gender = data.sex,
        },
        job = {
            name = data.profession?.name or 'unemployed',
            label = data.profession?.label or 'Unemployed',
            payment = data.profession?.salary or 0,
            onduty = data.profession?.onDuty or false,
            isboss = data.profession?.isBoss or false,
            grade = {
                name = data.profession?.rank or 'Freelancer',
                level = data.profession?.level or 0,
            }
        },
        gang = {
            name = data.organization?.name or 'none',
            label = data.organization?.label or 'No Gang',
            isboss = data.organization?.isLeader or false,
            grade = {
                name = data.organization?.rank or 'Member',
                level = data.organization?.level or 0,
            }
        },
        metadata = {
            hunger = data.status?.hunger or 100,
            thirst = data.status?.thirst or 100,
            stress = data.status?.stress or 0,
            isdead = data.isDead or false,
        },
        items = data.inventory or {},
    }
    
    TriggerEvent('QBCore:Player:SetPlayerData', QBCore.PlayerData)
end)

-- Job Update
RegisterNetEvent('vCore:Client:OnProfessionUpdate', function(profession)
    QBCore.PlayerData.job = {
        name = profession.name,
        label = profession.label,
        payment = profession.salary,
        onduty = profession.onDuty,
        isboss = profession.isBoss,
        grade = {
            name = profession.rank,
            level = profession.level,
        }
    }
    TriggerEvent('QBCore:Client:OnJobUpdate', QBCore.PlayerData.job)
end)

-- Gang Update
RegisterNetEvent('vCore:Client:OnOrganizationUpdate', function(organization)
    QBCore.PlayerData.gang = {
        name = organization.name,
        label = organization.label,
        isboss = organization.isLeader,
        grade = {
            name = organization.rank,
            level = organization.level,
        }
    }
    TriggerEvent('QBCore:Client:OnGangUpdate', QBCore.PlayerData.gang)
end)

-- Functions
QBCore.Functions.GetPlayerData = function(cb)
    if cb then
        cb(QBCore.PlayerData)
    else
        return QBCore.PlayerData
    end
end

QBCore.Functions.GetCoords = function(entity)
    return VCore.Functions.GetCoords(entity)
end

QBCore.Functions.HasItem = function(item, amount)
    return VCore.Functions.HasItem(item, amount)
end

QBCore.Functions.Notify = function(text, notifyType, duration)
    VCore.Functions.Notify(text, notifyType, duration)
end

QBCore.Functions.DrawText = function(text, position)
    VCore.Functions.DrawText(text, position)
end

QBCore.Functions.HideText = function()
    VCore.Functions.HideText()
end

QBCore.Functions.KeyPressed = function()
    VCore.Functions.KeyPressed()
end

QBCore.Functions.SpawnVehicle = function(model, cb, coords, isnetworked, teleportInto)
    VCore.Functions.SpawnVehicle(model, cb, coords, isnetworked, teleportInto)
end

QBCore.Functions.DeleteVehicle = function(vehicle)
    VCore.Functions.DeleteVehicle(vehicle)
end

QBCore.Functions.GetVehicles = function()
    return VCore.Functions.GetVehicles()
end

QBCore.Functions.GetObjects = function()
    return VCore.Functions.GetObjects()
end

QBCore.Functions.GetPlayers = function()
    return VCore.Functions.GetPlayers()
end

QBCore.Functions.GetPlayersFromCoords = function(coords, distance)
    return VCore.Functions.GetPlayersFromCoords(coords, distance)
end

QBCore.Functions.GetClosestPlayer = function(coords, distance)
    return VCore.Functions.GetClosestPlayer(coords, distance)
end

QBCore.Functions.GetClosestPed = function(coords, ignoreList)
    return VCore.Functions.GetClosestPed(coords, ignoreList)
end

QBCore.Functions.GetClosestVehicle = function(coords)
    return VCore.Functions.GetClosestVehicle(coords)
end

QBCore.Functions.GetClosestObject = function(coords)
    return VCore.Functions.GetClosestObject(coords)
end

QBCore.Functions.TriggerCallback = function(name, cb, ...)
    VCore.Functions.TriggerCallback(name, cb, ...)
end

QBCore.Functions.Progressbar = function(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
    VCore.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel)
end

-- Shared Data
QBCore.Shared.Jobs = Config.Professions.Types
QBCore.Shared.Gangs = {}
QBCore.Shared.Items = VCore.Shared.Items
QBCore.Shared.Vehicles = {}
QBCore.Shared.Weapons = {}

-- Export QBCore object
exports('GetCoreObject', function()
    return QBCore
end)

-- Legacy support
if Config.Bridge.EnableLegacySupport then
    _G.QBCore = QBCore
end

print('^2[vCore Bridge]^7 QBCore client compatibility layer loaded')