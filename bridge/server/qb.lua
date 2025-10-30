-- ┌─────────────────────────────────────────────────────────┐
-- │ QBCore Bridge - Server Side                             │
-- │ Makes vCore compatible with QBCore resources            │
-- └─────────────────────────────────────────────────────────┘

if not Config.Bridge.EnableLegacySupport then return end

QBCore = {}
QBCore.Config = Config
QBCore.Shared = {}
QBCore.Functions = {}
QBCore.Player = {}
QBCore.Commands = {}
QBCore.UseableItems = {}

-- Player Management
QBCore.Functions.GetPlayer = function(source)
    local vPlayer = VCore.Functions.GetPlayer(source)
    if not vPlayer then return nil end
    
    -- Create QBCore-compatible player object
    local qbPlayer = {}
    qbPlayer.PlayerData = {
        source = vPlayer.PlayerData.source,
        citizenid = vPlayer.PlayerData.citizenid,
        license = vPlayer.PlayerData.identifier,
        name = vPlayer.PlayerData.firstName .. ' ' .. vPlayer.PlayerData.lastName,
        money = {
            cash = vPlayer.PlayerData.currencies.cash or 0,
            bank = vPlayer.PlayerData.currencies.bank or 0,
            crypto = vPlayer.PlayerData.currencies.crypto or 0,
        },
        charinfo = {
            firstname = vPlayer.PlayerData.firstName,
            lastname = vPlayer.PlayerData.lastName,
            birthdate = vPlayer.PlayerData.dob,
            gender = vPlayer.PlayerData.sex,
            nationality = vPlayer.PlayerData.nationality or 'USA',
            phone = vPlayer.PlayerData.phone or 'Unknown',
            account = vPlayer.PlayerData.bankAccount or 'Unknown',
        },
        job = {
            name = vPlayer.PlayerData.profession?.name or 'unemployed',
            label = vPlayer.PlayerData.profession?.label or 'Unemployed',
            payment = vPlayer.PlayerData.profession?.salary or 0,
            onduty = vPlayer.PlayerData.profession?.onDuty or false,
            isboss = vPlayer.PlayerData.profession?.isBoss or false,
            grade = {
                name = vPlayer.PlayerData.profession?.rank or 'Freelancer',
                level = vPlayer.PlayerData.profession?.level or 0,
            }
        },
        gang = {
            name = vPlayer.PlayerData.organization?.name or 'none',
            label = vPlayer.PlayerData.organization?.label or 'No Gang',
            isboss = vPlayer.PlayerData.organization?.isLeader or false,
            grade = {
                name = vPlayer.PlayerData.organization?.rank or 'Member',
                level = vPlayer.PlayerData.organization?.level or 0,
            }
        },
        position = vPlayer.PlayerData.position or Config.Spawn.DefaultCoords,
        metadata = {
            hunger = vPlayer.PlayerData.status?.hunger or 100,
            thirst = vPlayer.PlayerData.status?.thirst or 100,
            stress = vPlayer.PlayerData.status?.stress or 0,
            isdead = vPlayer.PlayerData.isDead or false,
            inlaststand = vPlayer.PlayerData.inLastStand or false,
            armor = vPlayer.PlayerData.armor or 0,
            ishandcuffed = vPlayer.PlayerData.isHandcuffed or false,
            callsign = vPlayer.PlayerData.callsign or 'NO CALLSIGN',
            bloodtype = vPlayer.PlayerData.bloodType or 'O+',
            dealerrep = vPlayer.PlayerData.reputation?.gangs or 0,
            fingerprint = vPlayer.PlayerData.fingerprint or 'Unknown',
            walletid = vPlayer.PlayerData.walletId or 'Unknown',
        },
        items = vPlayer.PlayerData.inventory or {},
    }
    
    -- Bridge Functions
    qbPlayer.Functions = {}
    
    qbPlayer.Functions.UpdatePlayerData = function()
        vPlayer.Functions.UpdatePlayerData()
    end
    
    qbPlayer.Functions.SetJob = function(job, grade)
        return vPlayer.Functions.SetProfession(job, grade)
    end
    
    qbPlayer.Functions.SetGang = function(gang, grade)
        return vPlayer.Functions.SetOrganization(gang, grade)
    end
    
    qbPlayer.Functions.SetJobDuty = function(onDuty)
        vPlayer.Functions.SetDuty(onDuty)
    end
    
    qbPlayer.Functions.AddMoney = function(moneyType, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(moneyType, 'qb', 'vcore')
        return vPlayer.Functions.AddCurrency(vcoreCurrency, amount, reason)
    end
    
    qbPlayer.Functions.RemoveMoney = function(moneyType, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(moneyType, 'qb', 'vcore')
        return vPlayer.Functions.RemoveCurrency(vcoreCurrency, amount, reason)
    end
    
    qbPlayer.Functions.SetMoney = function(moneyType, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(moneyType, 'qb', 'vcore')
        return vPlayer.Functions.SetCurrency(vcoreCurrency, amount, reason)
    end
    
    qbPlayer.Functions.GetMoney = function(moneyType)
        local vcoreCurrency = Bridge.ConvertCurrency(moneyType, 'qb', 'vcore')
        return vPlayer.Functions.GetCurrency(vcoreCurrency)
    end
    
    qbPlayer.Functions.AddItem = function(item, amount, slot, info)
        return vPlayer.Functions.AddItem(item, amount, slot, info)
    end
    
    qbPlayer.Functions.RemoveItem = function(item, amount, slot)
        return vPlayer.Functions.RemoveItem(item, amount, slot)
    end
    
    qbPlayer.Functions.GetItemByName = function(item)
        return vPlayer.Functions.GetItem(item)
    end
    
    qbPlayer.Functions.GetItemBySlot = function(slot)
        return vPlayer.Functions.GetItemBySlot(slot)
    end
    
    qbPlayer.Functions.Save = function()
        vPlayer.Functions.Save()
    end
    
    return qbPlayer
end

QBCore.Functions.GetPlayerByCitizenId = function(citizenid)
    return QBCore.Functions.GetPlayer(VCore.Functions.GetSource(citizenid))
end

QBCore.Functions.GetPlayers = function()
    local players = {}
    for _, source in pairs(VCore.Functions.GetPlayers()) do
        table.insert(players, QBCore.Functions.GetPlayer(source))
    end
    return players
end

QBCore.Functions.GetPlayerByPhone = function(phone)
    -- Implementation depends on vCore's phone system
    return nil
end

QBCore.Functions.GetSource = function(identifier)
    return VCore.Functions.GetSource(identifier)
end

-- Permissions
QBCore.Functions.HasPermission = function(source, permission)
    return VCore.Functions.HasPermission(source, permission)
end

QBCore.Functions.GetPermission = function(source)
    return VCore.Functions.GetPermission(source)
end

-- Notifications
QBCore.Functions.Notify = function(source, text, notifyType, duration)
    VCore.Functions.Notify(source, text, notifyType, duration)
end

-- Callbacks
QBCore.Functions.CreateCallback = function(name, cb)
    VCore.Functions.CreateCallback(name, cb)
end

QBCore.Functions.TriggerCallback = function(name, source, cb, ...)
    VCore.Functions.TriggerCallback(name, source, cb, ...)
end

-- Useable Items
QBCore.Functions.CreateUseableItem = function(item, cb)
    VCore.Functions.CreateUseableItem(item, cb)
end

QBCore.Functions.CanUseItem = function(item)
    return VCore.Functions.CanUseItem(item)
end

QBCore.Functions.UseItem = function(source, item)
    VCore.Functions.UseItem(source, item)
end

-- Kick
QBCore.Functions.Kick = function(source, reason, setKickReason, deferrals)
    VCore.Functions.Kick(source, reason, setKickReason, deferrals)
end

-- Bans
QBCore.Functions.IsPlayerBanned = function(license)
    return VCore.Functions.IsPlayerBanned(license)
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

print('^2[vCore Bridge]^7 QBCore compatibility layer loaded')