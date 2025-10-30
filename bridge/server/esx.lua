-- ┌─────────────────────────────────────────────────────────┐
-- │ ESX Bridge - Server Side                                │
-- │ Makes vCore compatible with ESX resources                │
-- └─────────────────────────────────────────────────────────┘

if not Config.Bridge.EnableLegacySupport then return end

ESX = {}
ESX.PlayerData = {}
ESX.Players = {}

-- Get ESX Object
function ESX.GetPlayerFromId(source)
    local vPlayer = VCore.Functions.GetPlayer(source)
    if not vPlayer then return nil end
    
    -- Create ESX-compatible player object
    local xPlayer = {}
    xPlayer.source = vPlayer.PlayerData.source
    xPlayer.identifier = vPlayer.PlayerData.identifier
    xPlayer.name = vPlayer.PlayerData.firstName .. ' ' .. vPlayer.PlayerData.lastName
    xPlayer.firstname = vPlayer.PlayerData.firstName
    xPlayer.lastname = vPlayer.PlayerData.lastName
    xPlayer.dateofbirth = vPlayer.PlayerData.dob
    xPlayer.sex = vPlayer.PlayerData.sex
    xPlayer.height = vPlayer.PlayerData.height or 180
    xPlayer.job = {
        name = vPlayer.PlayerData.profession?.name or 'unemployed',
        label = vPlayer.PlayerData.profession?.label or 'Unemployed',
        grade = vPlayer.PlayerData.profession?.level or 0,
        grade_name = vPlayer.PlayerData.profession?.rank or 'Employee',
        grade_label = vPlayer.PlayerData.profession?.rank or 'Employee',
        grade_salary = vPlayer.PlayerData.profession?.salary or 0,
        skin_male = {},
        skin_female = {},
    }
    
    -- Accounts (ESX style)
    xPlayer.accounts = {
        {name = 'money', money = vPlayer.PlayerData.currencies.cash or 0, label = 'Cash'},
        {name = 'bank', money = vPlayer.PlayerData.currencies.bank or 0, label = 'Bank'},
        {name = 'black_money', money = vPlayer.PlayerData.currencies.crypto or 0, label = 'Black Money'},
    }
    
    xPlayer.coords = vPlayer.PlayerData.position or Config.Spawn.DefaultCoords
    xPlayer.maxWeight = vPlayer.PlayerData.maxWeight or 30000
    xPlayer.inventory = vPlayer.PlayerData.inventory or {}
    
    -- ESX Functions
    function xPlayer.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, xPlayer.source, ...)
    end
    
    function xPlayer.setJob(job, grade)
        return vPlayer.Functions.SetProfession(job, grade)
    end
    
    function xPlayer.getJob()
        return xPlayer.job
    end
    
    function xPlayer.addMoney(amount, reason)
        return vPlayer.Functions.AddCurrency('cash', amount, reason)
    end
    
    function xPlayer.removeMoney(amount, reason)
        return vPlayer.Functions.RemoveCurrency('cash', amount, reason)
    end
    
    function xPlayer.getMoney()
        return vPlayer.Functions.GetCurrency('cash')
    end
    
    function xPlayer.addAccountMoney(account, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(account, 'esx', 'vcore')
        return vPlayer.Functions.AddCurrency(vcoreCurrency, amount, reason)
    end
    
    function xPlayer.removeAccountMoney(account, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(account, 'esx', 'vcore')
        return vPlayer.Functions.RemoveCurrency(vcoreCurrency, amount, reason)
    end
    
    function xPlayer.getAccount(account)
        local vcoreCurrency = Bridge.ConvertCurrency(account, 'esx', 'vcore')
        local amount = vPlayer.Functions.GetCurrency(vcoreCurrency)
        return {name = account, money = amount, label = vcoreCurrency}
    end
    
    function xPlayer.setAccountMoney(account, amount, reason)
        local vcoreCurrency = Bridge.ConvertCurrency(account, 'esx', 'vcore')
        return vPlayer.Functions.SetCurrency(vcoreCurrency, amount, reason)
    end
    
    function xPlayer.getInventory(minimal)
        return xPlayer.inventory
    end
    
    function xPlayer.addInventoryItem(item, count, metadata)
        return vPlayer.Functions.AddItem(item, count, nil, metadata)
    end
    
    function xPlayer.removeInventoryItem(item, count)
        return vPlayer.Functions.RemoveItem(item, count)
    end
    
    function xPlayer.getInventoryItem(item)
        return vPlayer.Functions.GetItem(item)
    end
    
    function xPlayer.canCarryItem(item, count)
        return vPlayer.Functions.CanCarryItem(item, count)
    end
    
    function xPlayer.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        return true -- Implement based on your inventory system
    end
    
    function xPlayer.setMaxWeight(weight)
        vPlayer.PlayerData.maxWeight = weight
        vPlayer.Functions.UpdatePlayerData()
    end
    
    function xPlayer.getWeight()
        return vPlayer.Functions.GetWeight()
    end
    
    function xPlayer.getName()
        return xPlayer.name
    end
    
    function xPlayer.setName(newName)
        local split = {}
        for word in string.gmatch(newName, "[^%s]+") do
            table.insert(split, word)
        end
        vPlayer.PlayerData.firstName = split[1] or 'John'
        vPlayer.PlayerData.lastName = split[2] or 'Doe'
        vPlayer.Functions.UpdatePlayerData()
    end
    
    function xPlayer.getCoords()
        return xPlayer.coords
    end
    
    function xPlayer.kick(reason)
        VCore.Functions.Kick(xPlayer.source, reason)
    end
    
    function xPlayer.showNotification(msg, notifyType, length)
        VCore.Functions.Notify(xPlayer.source, msg, notifyType or 'inform', length or 5000)
    end
    
    function xPlayer.showHelpNotification(msg)
        VCore.Functions.Notify(xPlayer.source, msg, 'inform', 5000)
    end
    
    return xPlayer
end

function ESX.GetPlayerFromIdentifier(identifier)
    local source = VCore.Functions.GetSource(identifier)
    if source then
        return ESX.GetPlayerFromId(source)
    end
    return nil
end

function ESX.GetPlayers()
    local players = {}
    for _, source in pairs(VCore.Functions.GetPlayers()) do
        table.insert(players, ESX.GetPlayerFromId(source))
    end
    return players
end

function ESX.RegisterServerCallback(name, cb)
    VCore.Functions.CreateCallback(name, cb)
end

function ESX.UseItem(source, item)
    VCore.Functions.UseItem(source, item)
end

function ESX.RegisterUsableItem(item, cb)
    VCore.Functions.CreateUseableItem(item, cb)
end

function ESX.GetItemLabel(item)
    local itemData = VCore.Shared.GetItem(item)
    return itemData and itemData.label or item
end

function ESX.SavePlayer(xPlayer)
    local vPlayer = VCore.Functions.GetPlayer(xPlayer.source)
    if vPlayer then
        vPlayer.Functions.Save()
    end
end

function ESX.SavePlayers()
    for source, _ in pairs(VCore.Players) do
        local vPlayer = VCore.Functions.GetPlayer(source)
        if vPlayer then
            vPlayer.Functions.Save()
        end
    end
end

function ESX.ShowNotification(source, msg, notifyType, length)
    VCore.Functions.Notify(source, msg, notifyType or 'inform', length or 5000)
end

-- Export ESX object
exports('getSharedObject', function()
    return ESX
end)

-- Legacy support
if Config.Bridge.EnableLegacySupport then
    _G.ESX = ESX
end

print('^2[vCore Bridge]^7 ESX compatibility layer loaded')