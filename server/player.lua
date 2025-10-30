VCore.Functions.CreatePlayer = function(source, citizenid)
    local src = source
    local Player = {}
    
    Player.PlayerData = {
        source = src,
        citizenid = citizenid or VCore.Player.CreateCitizenId(),
        license = VCore.Functions.GetIdentifier(src, 'license'),
        name = GetPlayerName(src),
        money = {},
        charinfo = {},
        job = {},
        gang = {},
        position = Config.DefaultSpawn,
        metadata = {
            hunger = 100,
            thirst = 100,
            stress = 0,
            isdead = false,
            inlaststand = false,
            armor = 0,
            ishandcuffed = false,
            tracker = false,
            injail = 0,
            jailitems = {},
            status = {},
            phone = {},
            fitbit = {},
            commandbinds = {},
            bloodtype = Config.Player.Bloodtypes[math.random(1, #Config.Player.Bloodtypes)],
            dealerrep = 0,
            craftingrep = 0,
            attachmentcraftingrep = 0,
            currentapartment = nil,
            callsign = 'NO CALLSIGN',
            fingerprint = VCore.Player.CreateFingerId(),
            walletid = VCore.Player.CreateWalletId(),
            criminalrecord = {
                hasRecord = false,
                date = nil
            },
            licences = {
                driver = true,
                business = false,
                weapon = false
            },
            inside = {
                house = nil,
                apartment = {
                    apartmentType = nil,
                    apartmentId = nil,
                }
            },
            phonedata = {
                SerialNumber = VCore.Player.CreateSerialNumber(),
                InstalledApps = {}
            }
        },
        inventory = {},
        optin = true
    }
    
    -- Initialize money accounts
    for _, moneyType in pairs(Config.Money.MoneyTypes) do
        Player.PlayerData.money[moneyType] = 0
    end
    
    Player.Functions = {}
    
    Player.Functions.UpdatePlayerData = function()
        TriggerClientEvent('vCore:Client:OnPlayerLoaded', src)
        TriggerClientEvent('vCore:Player:SetPlayerData', src, Player.PlayerData)
    end
    
    Player.Functions.SetJob = function(job, grade)
        local job = job
        local grade = tostring(grade) or '0'
        
        if not Config.Jobs[job] then return false end
        
        Player.PlayerData.job.name = job
        Player.PlayerData.job.label = Config.Jobs[job].label
        Player.PlayerData.job.payment = Config.Jobs[job].grades[grade].payment or 30
        Player.PlayerData.job.onduty = Config.Jobs[job].defaultDuty
        Player.PlayerData.job.isboss = Config.Jobs[job].grades[grade].isboss or false
        Player.PlayerData.job.grade = {
            name = Config.Jobs[job].grades[grade].name,
            level = tonumber(grade)
        }
        
        Player.Functions.UpdatePlayerData()
        TriggerClientEvent('vCore:Client:OnJobUpdate', src, Player.PlayerData.job)
        return true
    end
    
    Player.Functions.SetGang = function(gang, grade)
        local gang = gang
        local grade = tostring(grade) or '0'
        
        if not Config.Gangs[gang] then return false end
        
        Player.PlayerData.gang.name = gang
        Player.PlayerData.gang.label = Config.Gangs[gang].label
        Player.PlayerData.gang.isboss = Config.Gangs[gang].grades[grade].isboss or false
        Player.PlayerData.gang.grade = {
            name = Config.Gangs[gang].grades[grade].name,
            level = tonumber(grade)
        }
        
        Player.Functions.UpdatePlayerData()
        TriggerClientEvent('vCore:Client:OnGangUpdate', src, Player.PlayerData.gang)
        return true
    end
    
    Player.Functions.SetJobDuty = function(onDuty)
        Player.PlayerData.job.onduty = not Player.PlayerData.job.onduty
        TriggerClientEvent('vCore:Client:SetDuty', src, Player.PlayerData.job.onduty)
        Player.Functions.UpdatePlayerData()
    end
    
    Player.Functions.SetPlayerData = function(key, val)
        if not key or type(key) ~= 'string' then return end
        Player.PlayerData[key] = val
        Player.Functions.UpdatePlayerData()
    end
    
    Player.Functions.SetMetaData = function(meta, val)
        if not meta or type(meta) ~= 'string' then return end
        if meta == 'hunger' or meta == 'thirst' then
            val = val > 100 and 100 or val
        end
        Player.PlayerData.metadata[meta] = val
        Player.Functions.UpdatePlayerData()
    end
    
    Player.Functions.AddMoney = function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not Player.PlayerData.money[moneytype] then return false end
        
        Player.PlayerData.money[moneytype] = Player.PlayerData.money[moneytype] + amount
        
        Player.Functions.UpdatePlayerData()
        
        if amount > 100000 then
            TriggerEvent('vCore:Server:MoneyLog', src, moneytype, amount, 'add', reason)
        end
        
        return true
    end
    
    Player.Functions.RemoveMoney = function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not Player.PlayerData.money[moneytype] then return false end
        
        for _, mtype in pairs(Config.Money.DontAllowMinus) do
            if mtype == moneytype then
                if (Player.PlayerData.money[moneytype] - amount) < 0 then
                    return false
                end
            end
        end
        
        Player.PlayerData.money[moneytype] = Player.PlayerData.money[moneytype] - amount
        
        Player.Functions.UpdatePlayerData()
        
        if amount > 100000 then
            TriggerEvent('vCore:Server:MoneyLog', src, moneytype, amount, 'remove', reason)
        end
        
        return true
    end
    
    Player.Functions.SetMoney = function(moneytype, amount, reason)
        reason = reason or 'unknown'
        moneytype = moneytype:lower()
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not Player.PlayerData.money[moneytype] then return false end
        
        Player.PlayerData.money[moneytype] = amount
        
        Player.Functions.UpdatePlayerData()
        return true
    end
    
    Player.Functions.GetMoney = function(moneytype)
        if not moneytype then return false end
        moneytype = moneytype:lower()
        return Player.PlayerData.money[moneytype]
    end
    
    Player.Functions.Save = function()
        MySQL.update('UPDATE players SET money = ?, charinfo = ?, job = ?, gang = ?, position = ?, metadata = ? WHERE citizenid = ?', {
            json.encode(Player.PlayerData.money),
            json.encode(Player.PlayerData.charinfo),
            json.encode(Player.PlayerData.job),
            json.encode(Player.PlayerData.gang),
            json.encode(Player.PlayerData.position),
            json.encode(Player.PlayerData.metadata),
            Player.PlayerData.citizenid
        })
        
        VCore.Debug('Saved player:', Player.PlayerData.name, '(' .. Player.PlayerData.citizenid .. ')')
    end
    
    Player.Functions.Logout = function()
        VCore.Player_Buckets[Player.PlayerData.source] = nil
        VCore.Players[src] = nil
    end
    
    Player.Functions.AddMethod = function(methodName, method)
        Player.Functions[methodName] = method
    end
    
    VCore.Players[src] = Player
    
    Player.Functions.UpdatePlayerData()
    
    return Player
end

VCore.Player = {}

VCore.Player.Login = function(source, citizenid, newData)
    local src = source
    local license = VCore.Functions.GetIdentifier(src, 'license')
    
    if not citizenid then
        return false
    end
    
    local PlayerData = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    
    if not PlayerData[1] then
        return false
    end
    
    local Player = VCore.Functions.CreatePlayer(src, citizenid)
    
    Player.PlayerData.money = json.decode(PlayerData[1].money) or {}
    Player.PlayerData.charinfo = json.decode(PlayerData[1].charinfo) or {}
    Player.PlayerData.job = json.decode(PlayerData[1].job) or {}
    Player.PlayerData.gang = json.decode(PlayerData[1].gang) or {}
    Player.PlayerData.position = json.decode(PlayerData[1].position) or Config.DefaultSpawn
    Player.PlayerData.metadata = json.decode(PlayerData[1].metadata) or {}
    Player.PlayerData.cid = PlayerData[1].cid
    
    Player.Functions.UpdatePlayerData()
    
    return true
end

VCore.Player.CreateCitizenId = function()
    local UniqueFound = false
    local CitizenId
    
    while not UniqueFound do
        CitizenId = tostring(VCore.Shared.RandomStr(3) .. VCore.Shared.RandomInt(5)):upper()
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE citizenid = ?', {CitizenId})
        if result == 0 then
            UniqueFound = true
        end
    end
    
    return CitizenId
end

VCore.Player.CreateFingerId = function()
    local UniqueFound = false
    local FingerId
    
    while not UniqueFound do
        FingerId = tostring(VCore.Shared.RandomStr(2) .. VCore.Shared.RandomInt(3) .. VCore.Shared.RandomStr(1) .. VCore.Shared.RandomInt(2) .. VCore.Shared.RandomStr(3) .. VCore.Shared.RandomInt(4))
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE JSON_EXTRACT(metadata, "$.fingerprint") = ?', {FingerId})
        if result == 0 then
            UniqueFound = true
        end
    end
    
    return FingerId
end

VCore.Player.CreateWalletId = function()
    local UniqueFound = false
    local WalletId
    
    while not UniqueFound do
        WalletId = 'VC-' .. math.random(11111111, 99999999)
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE JSON_EXTRACT(metadata, "$.walletid") = ?', {WalletId})
        if result == 0 then
            UniqueFound = true
        end
    end
    
    return WalletId
end

VCore.Player.CreateSerialNumber = function()
    local UniqueFound = false
    local SerialNumber
    
    while not UniqueFound do
        SerialNumber = math.random(11111111, 99999999)
        local result = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE JSON_EXTRACT(metadata, "$.phonedata.SerialNumber") = ?', {SerialNumber})
        if result == 0 then
            UniqueFound = true
        end
    end
    
    return SerialNumber
end

VCore.Functions.GetIdentifier = function(source, idtype)
    local identifiers = GetPlayerIdentifiers(source)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, idtype) then
            return identifier
        end
    end
    return nil
end

VCore.Functions.GetCoords = function(entity)
    local coords = GetEntityCoords(entity, false)
    local heading = GetEntityHeading(entity)
    return vector4(coords.x, coords.y, coords.z, heading)
end