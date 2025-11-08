-- ┌─────────────────────────────────────────────────────────┐
-- │ vCore Framework - Shared Core                           │
-- │ Unique Architecture: Module-Based System                 │
-- └─────────────────────────────────────────────────────────┘

VCore = {}
VCore.Version = '2.0.0'
VCore.Config = Config
VCore.Shared = {}
VCore.Modules = {}
VCore.ServerCallbacks = {}
VCore.ClientCallbacks = {}

-- ════════════════════════════════════════════════════════
-- MODULE SYSTEM (Unique to vCore)
-- ════════════════════════════════════════════════════════

VCore.RegisterModule = function(name, module)
    if VCore.Modules[name] then
        print('^3[vCore Warning]^7 Module "' .. name .. '" is being overwritten')
    end
    
    VCore.Modules[name] = module
    VCore.Debug('Module registered: ' .. name)
    
    -- Call module init if exists
    if module.Init then
        CreateThread(function()
            local success, err = pcall(module.Init)
            if not success then
                print('^1[vCore Module Error]^7 Failed to initialize module "' .. name .. '": ' .. err)
            end
        end)
    end
    
    return module
end

VCore.GetModule = function(name)
    return VCore.Modules[name]
end

VCore.HasModule = function(name)
    return VCore.Modules[name] ~= nil
end

-- ════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ════════════════════════════════════════════════════════

function VCore.Debug(...)
    if GetConvar('vcore:debug', 'false') == 'true' then
        local side = IsDuplicityVersion() and '^5[SERVER]^7' or '^6[CLIENT]^7'
        print('^3[vCore Debug]^7', side, ...)
    end
end

function VCore.Error(...)
    local side = IsDuplicityVersion() and '[SERVER]' or '[CLIENT]'
    print('^1[vCore Error]^7', side, ...)
end

function VCore.Success(...)
    local side = IsDuplicityVersion() and '[SERVER]' or '[CLIENT]'
    print('^2[vCore Success]^7', side, ...)
end

-- Math Utilities
VCore.Shared.Math = {
    Round = function(value, decimals)
        if not decimals then return math.floor(value + 0.5) end
        local power = 10 ^ decimals
        return math.floor((value * power) + 0.5) / power
    end,
    
    Clamp = function(value, min, max)
        return math.max(min, math.min(max, value))
    end,
    
    Lerp = function(a, b, t)
        return a + (b - a) * t
    end,
    
    Distance = function(v1, v2)
        if type(v1) == 'table' and type(v2) == 'table' then
            return #(vec3(v1.x, v1.y, v1.z) - vec3(v2.x, v2.y, v2.z))
        else
            return #(v1 - v2)
        end
    end,
}

-- String Utilities
VCore.Shared.String = {
    Trim = function(value)
        if not value then return nil end
        return (string.gsub(value, '^%s*(.-)%s*$', '%1'))
    end,
    
    Split = function(str, delimiter)
        local result = {}
        local from = 1
        local delimFrom, delimTo = string.find(str, delimiter, from)
        
        while delimFrom do
            result[#result + 1] = string.sub(str, from, delimFrom - 1)
            from = delimTo + 1
            delimFrom, delimTo = string.find(str, delimiter, from)
        end
        
        result[#result + 1] = string.sub(str, from)
        return result
    end,
    
    StartsWith = function(str, prefix)
        return string.sub(str, 1, string.len(prefix)) == prefix
    end,
    
    EndsWith = function(str, suffix)
        return suffix == '' or string.sub(str, -string.len(suffix)) == suffix
    end,
    
    Capitalize = function(str)
        return str:gsub('^%l', string.upper)
    end,
    
    Random = function(length, includeNumbers)
        if length <= 0 then return '' end
        local charset = includeNumbers and 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' or 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
        local result = ''
        
        for i = 1, length do
            local rand = math.random(1, #charset)
            result = result .. string.sub(charset, rand, rand)
        end
        
        return result
    end,
    
    RandomInt = function(length)
        if length <= 0 then return '' end
        local result = ''
        for i = 1, length do
            result = result .. tostring(math.random(0, 9))
        end
        return result
    end,
}

-- Table Utilities
VCore.Shared.Table = {
    Clone = function(tbl)
        if type(tbl) ~= 'table' then return tbl end
        local result = {}
        for k, v in pairs(tbl) do
            result[k] = type(v) == 'table' and VCore.Shared.Table.Clone(v) or v
        end
        return result
    end,
    
    Merge = function(t1, t2)
        for k, v in pairs(t2) do
            if type(v) == 'table' and type(t1[k]) == 'table' then
                VCore.Shared.Table.Merge(t1[k], v)
            else
                t1[k] = v
            end
        end
        return t1
    end,
    
    Contains = function(tbl, value)
        for _, v in pairs(tbl) do
            if v == value then return true end
        end
        return false
    end,
    
    Find = function(tbl, predicate)
        for k, v in pairs(tbl) do
            if predicate(v, k) then return v, k end
        end
        return nil
    end,
    
    Filter = function(tbl, predicate)
        local result = {}
        for k, v in pairs(tbl) do
            if predicate(v, k) then
                result[k] = v
            end
        end
        return result
    end,
    
    Map = function(tbl, mapper)
        local result = {}
        for k, v in pairs(tbl) do
            result[k] = mapper(v, k)
        end
        return result
    end,
    
    Size = function(tbl)
        local count = 0
        for _ in pairs(tbl) do count = count + 1 end
        return count
    end,
}

-- Time Utilities
VCore.Shared.Time = {
    GetTimestamp = function()
        return os.time()
    end,
    
    FormatTime = function(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local secs = seconds % 60
        return string.format('%02d:%02d:%02d', hours, minutes, secs)
    end,
    
    GetDate = function(timestamp)
        return os.date('*t', timestamp or os.time())
    end,
    
    FormatDate = function(timestamp, format)
        format = format or '%Y-%m-%d %H:%M:%S'
        return os.date(format, timestamp or os.time())
    end,
}

-- ════════════════════════════════════════════════════════
-- IDENTIFIER GENERATION (Unique System)
-- ════════════════════════════════════════════════════════

VCore.Shared.GenerateId = {
    -- Citizen ID: ABC12345 (3 letters + 5 numbers)
    CitizenId = function()
        return string.upper(VCore.Shared.String.Random(3, false) .. VCore.Shared.String.RandomInt(5))
    end,
    
    -- Fingerprint: AB1C2D3E4F (Complex pattern)
    Fingerprint = function()
        local pattern = ''
        for i = 1, 10 do
            if i % 2 == 0 then
                pattern = pattern .. VCore.Shared.String.RandomInt(1)
            else
                pattern = pattern .. VCore.Shared.String.Random(1, false)
            end
        end
        return string.upper(pattern)
    end,
    
    -- Wallet ID: VC-12345678
    WalletId = function()
        return 'VC-' .. VCore.Shared.String.RandomInt(8)
    end,
    
    -- Serial Number: 8 digit number
    SerialNumber = function()
        return tonumber(VCore.Shared.String.RandomInt(8))
    end,
    
    -- Phone Number: XXX-XXXX
    PhoneNumber = function()
        return VCore.Shared.String.RandomInt(3) .. '-' .. VCore.Shared.String.RandomInt(4)
    end,
    
    -- Bank Account: 10 digit number
    BankAccount = function()
        return VCore.Shared.String.RandomInt(10)
    end,
}

-- ════════════════════════════════════════════════════════
-- STARTER ITEMS
-- ════════════════════════════════════════════════════════

VCore.Shared.StarterItems = {
    {item = 'phone', amount = 1},
    {item = 'id_card', amount = 1},
    {item = 'water_bottle', amount = 2},
}

-- ════════════════════════════════════════════════════════
-- BLOOD TYPES
-- ════════════════════════════════════════════════════════

VCore.Shared.BloodTypes = {'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'}

-- ════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════

if IsDuplicityVersion() then
    print('^2╔═══════════════════════════════════════════════════╗^7')
    print('^2║^7        vCore Framework v' .. VCore.Version .. ' ^5[SERVER]^7        ^2║^7')
    print('^2║^7  Next-Gen Framework with Bridge Support       ^2║^7')
    print('^2╚═══════════════════════════════════════════════════╝^7')
else
    print('^2╔═══════════════════════════════════════════════════╗^7')
    print('^2║^7        vCore Framework v' .. VCore.Version .. ' ^6[CLIENT]^7        ^2║^7')
    print('^2║^7  Next-Gen Framework with Bridge Support       ^2║^7')
    print('^2╚═══════════════════════════════════════════════════╝^7')
end