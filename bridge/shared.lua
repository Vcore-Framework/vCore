-- ┌─────────────────────────────────────────────────────────┐
-- │ vCore Multi-Framework Bridge System                     │
-- │ Allows resources from QB, ESX, and OX to work with vCore│
-- └─────────────────────────────────────────────────────────┘

Bridge = {}
Bridge.Framework = Config.Bridge.Framework or 'vcore'

-- Detect which framework scripts expect
function Bridge.DetectFramework()
    if Config.Bridge.AutoDetect then
        -- Check for QBCore exports
        local qbSuccess = pcall(function()
            return exports['qb-core']
        end)
        
        -- Check for ESX exports
        local esxSuccess = pcall(function()
            return exports['es_extended']
        end)
        
        -- Check for OX exports
        local oxSuccess = pcall(function()
            return exports['ox_core']
        end)
        
        if qbSuccess then
            Bridge.Framework = 'qb'
            print('^3[vCore Bridge]^7 Detected QBCore resource trying to load')
        elseif esxSuccess then
            Bridge.Framework = 'esx'
            print('^3[vCore Bridge]^7 Detected ESX resource trying to load')
        elseif oxSuccess then
            Bridge.Framework = 'ox'
            print('^3[vCore Bridge]^7 Detected OX resource trying to load')
        else
            Bridge.Framework = 'vcore'
        end
    end
    
    return Bridge.Framework
end

-- Universal data structure mapping
Bridge.DataMap = {
    vcore_to_qb = {
        citizenid = 'citizenid',
        identifier = 'license',
        firstName = 'charinfo.firstname',
        lastName = 'charinfo.lastname',
        dob = 'charinfo.birthdate',
        sex = 'charinfo.gender',
        profession = 'job',
        organization = 'gang',
        currencies = 'money',
    },
    
    vcore_to_esx = {
        citizenid = 'identifier',
        identifier = 'identifier',
        firstName = 'firstname',
        lastName = 'lastname',
        dob = 'dateofbirth',
        sex = 'sex',
        profession = 'job',
        organization = 'gang',
        currencies = 'accounts',
    },
    
    vcore_to_ox = {
        citizenid = 'charid',
        identifier = 'stateId',
        firstName = 'firstName',
        lastName = 'lastName',
        dob = 'dateOfBirth',
        sex = 'gender',
        profession = 'groups',
        organization = 'groups',
        currencies = 'accounts',
    }
}

-- Currency mapping between frameworks
Bridge.CurrencyMap = {
    qb = {
        cash = 'cash',
        bank = 'bank',
        crypto = 'crypto',
    },
    esx = {
        cash = 'money',
        bank = 'bank',
        crypto = 'black_money',
    },
    ox = {
        cash = 'money',
        bank = 'bank',
        crypto = 'crypto',
    }
}

-- Convert vCore data to target framework format
function Bridge.ConvertData(data, targetFramework)
    if not data then return nil end
    if targetFramework == 'vcore' then return data end
    
    local converted = {}
    local map = Bridge.DataMap['vcore_to_' .. targetFramework]
    
    if not map then
        print('^1[vCore Bridge Error]^7 Unknown target framework: ' .. targetFramework)
        return data
    end
    
    for vcoreKey, targetKey in pairs(map) do
        if data[vcoreKey] then
            -- Handle nested keys (e.g., 'charinfo.firstname')
            if string.find(targetKey, '%.') then
                local keys = {}
                for key in string.gmatch(targetKey, '[^%.]+') do
                    table.insert(keys, key)
                end
                
                local current = converted
                for i = 1, #keys - 1 do
                    if not current[keys[i]] then
                        current[keys[i]] = {}
                    end
                    current = current[keys[i]]
                end
                current[keys[#keys]] = data[vcoreKey]
            else
                converted[targetKey] = data[vcoreKey]
            end
        end
    end
    
    return converted
end

-- Convert currency name between frameworks
function Bridge.ConvertCurrency(currencyName, fromFramework, toFramework)
    if fromFramework == toFramework then return currencyName end
    
    -- First convert to vCore standard
    local vcoreCurrency = currencyName
    if fromFramework ~= 'vcore' then
        for vcore, foreign in pairs(Bridge.CurrencyMap[fromFramework] or {}) do
            if foreign == currencyName then
                vcoreCurrency = vcore
                break
            end
        end
    end
    
    -- Then convert to target framework
    if toFramework == 'vcore' then
        return vcoreCurrency
    else
        return Bridge.CurrencyMap[toFramework][vcoreCurrency] or vcoreCurrency
    end
end

-- Helper function to get nested values
function Bridge.GetNestedValue(tbl, path)
    local keys = {}
    for key in string.gmatch(path, '[^%.]+') do
        table.insert(keys, key)
    end
    
    local value = tbl
    for _, key in ipairs(keys) do
        if type(value) == 'table' and value[key] ~= nil then
            value = value[key]
        else
            return nil
        end
    end
    
    return value
end

-- Helper function to set nested values
function Bridge.SetNestedValue(tbl, path, value)
    local keys = {}
    for key in string.gmatch(path, '[^%.]+') do
        table.insert(keys, key)
    end
    
    local current = tbl
    for i = 1, #keys - 1 do
        if not current[keys[i]] then
            current[keys[i]] = {}
        end
        current = current[keys[i]]
    end
    
    current[keys[#keys]] = value
end

print('^2[vCore Bridge]^7 Shared Module Loaded')