-- ╔════════════════════════════════════════════════════════╗
-- ║  vCore API System - Enterprise Edition                ║
-- ║  RESTful-style Internal API with Rate Limiting        ║
-- ╚════════════════════════════════════════════════════════╝

VCore.API = {}
VCore.API.Version = '1.0.0'
VCore.API.Endpoints = {}
VCore.API.RateLimit = {}
VCore.API.Cache = {}

-- ════════════════════════════════════════════════════════
-- RATE LIMITING
-- ════════════════════════════════════════════════════════

VCore.API.RateLimiter = {
    limits = {
        default = {requests = 100, window = 60000}, -- 100 requests per minute
        auth = {requests = 10, window = 60000}, -- 10 requests per minute
        expensive = {requests = 10, window = 60000}, -- 10 expensive ops per minute
    },
    tracking = {}
}

function VCore.API.RateLimiter:Check(source, limitType)
    limitType = limitType or 'default'
    local limit = self.limits[limitType]
    
    if not self.tracking[source] then
        self.tracking[source] = {}
    end
    
    if not self.tracking[source][limitType] then
        self.tracking[source][limitType] = {
            requests = 0,
            resetTime = GetGameTimer() + limit.window
        }
    end
    
    local tracker = self.tracking[source][limitType]
    
    -- Reset if window expired
    if GetGameTimer() > tracker.resetTime then
        tracker.requests = 0
        tracker.resetTime = GetGameTimer() + limit.window
    end
    
    -- Check limit
    if tracker.requests >= limit.requests then
        return false, 'Rate limit exceeded'
    end
    
    tracker.requests = tracker.requests + 1
    return true, tracker.requests
end

function VCore.API.RateLimiter:Reset(source, limitType)
    if not self.tracking[source] then return end
    
    if limitType then
        self.tracking[source][limitType] = nil
    else
        self.tracking[source] = nil
    end
end

-- ════════════════════════════════════════════════════════
-- API ENDPOINT REGISTRY
-- ════════════════════════════════════════════════════════

function VCore.API:RegisterEndpoint(name, config)
    if self.Endpoints[name] then
        VCore.Error('API Endpoint already exists: ' .. name)
        return false
    end
    
    self.Endpoints[name] = {
        name = name,
        handler = config.handler,
        rateLimit = config.rateLimit or 'default',
        permissions = config.permissions or {},
        cache = config.cache or false,
        cacheDuration = config.cacheDuration or 300000,
        validator = config.validator,
        transform = config.transform
    }
    
    VCore.Debug('Registered API endpoint: ' .. name)
    return true
end

function VCore.API:Call(source, endpoint, data, callback)
    if not self.Endpoints[endpoint] then
        if callback then callback({success = false, error = 'Unknown endpoint'}) end
        return false
    end
    
    local ep = self.Endpoints[endpoint]
    
    -- Rate limiting
    local allowed, remaining = self.RateLimiter:Check(source, ep.rateLimit)
    if not allowed then
        if callback then callback({success = false, error = remaining}) end
        return false
    end
    
    -- Permission check
    if #ep.permissions > 0 then
        local hasPermission = false
        for _, perm in ipairs(ep.permissions) do
            if VCore.Functions.HasPermission(source, perm) then
                hasPermission = true
                break
            end
        end
        
        if not hasPermission then
            if callback then callback({success = false, error = 'Insufficient permissions'}) end
            return false
        end
    end
    
    -- Validation
    if ep.validator and not ep.validator(data) then
        if callback then callback({success = false, error = 'Invalid data'}) end
        return false
    end
    
    -- Cache check
    if ep.cache then
        local cacheKey = endpoint .. json.encode(data or {})
        local cached = self.Cache[cacheKey]
        
        if cached and GetGameTimer() < cached.expires then
            VCore.Debug('API Cache hit: ' .. endpoint)
            if callback then callback({success = true, data = cached.data, cached = true}) end
            return true
        end
    end
    
    -- Execute handler
    local success, result = pcall(function()
        return ep.handler(source, data)
    end)
    
    if not success then
        VCore.Error('API endpoint error (' .. endpoint .. '): ' .. result)
        if callback then callback({success = false, error = 'Internal error'}) end
        return false
    end
    
    -- Transform result
    if ep.transform then
        result = ep.transform(result)
    end
    
    -- Cache result
    if ep.cache then
        local cacheKey = endpoint .. json.encode(data or {})
        self.Cache[cacheKey] = {
            data = result,
            expires = GetGameTimer() + ep.cacheDuration
        }
    end
    
    if callback then callback({success = true, data = result}) end
    return true
end

-- ════════════════════════════════════════════════════════
-- CORE API ENDPOINTS
-- ════════════════════════════════════════════════════════

-- Player Endpoints
VCore.API:RegisterEndpoint('player:get', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return nil end
        return Player.data
    end,
    cache = true,
    cacheDuration = 30000
})

VCore.API:RegisterEndpoint('player:getById', {
    handler = function(source, data)
        if not data.citizenid then return nil end
        local Player = VCore.Functions.GetPlayerByCitizenId(data.citizenid)
        if not Player then return nil end
        return Player.data
    end,
    permissions = {'admin'},
    rateLimit = 'expensive'
})

VCore.API:RegisterEndpoint('player:update', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        if data.field and data.value then
            Player.data[data.field] = data.value
            Player:Save()
            return true
        end
        
        return false
    end,
    validator = function(data)
        return data.field ~= nil and data.value ~= nil
    end
})

VCore.API:RegisterEndpoint('player:addCurrency', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:AddCurrency(data.currency, data.amount, data.reason)
    end,
    permissions = {'admin'},
    validator = function(data)
        return data.currency and data.amount and data.amount > 0
    end
})

-- Profession Endpoints
VCore.API:RegisterEndpoint('profession:set', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:SetProfession(data.profession, data.level or 0, data.isPrimary)
    end,
    permissions = {'admin'},
    validator = function(data)
        return data.profession and Config.Professions.Types[data.profession]
    end
})

VCore.API:RegisterEndpoint('profession:addXP', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:AddProfessionXP(data.amount, data.profession)
    end,
    validator = function(data)
        return data.amount and data.amount > 0
    end
})

-- Skill Endpoints
VCore.API:RegisterEndpoint('skill:addXP', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:AddSkillXP(data.skill, data.amount)
    end,
    validator = function(data)
        return data.skill and data.amount and Config.Skills.Types[data.skill]
    end
})

VCore.API:RegisterEndpoint('skill:get', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return nil end
        
        if data.skill then
            return Player.data.skills[data.skill]
        end
        
        return Player.data.skills
    end,
    cache = true
})

-- Organization Endpoints
VCore.API:RegisterEndpoint('organization:set', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:SetOrganization(data.organization, data.level or 0, data.isLeader)
    end,
    permissions = {'admin'}
})

-- Status Endpoints
VCore.API:RegisterEndpoint('status:set', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return false end
        
        return Player:SetStatus(data.status, data.value)
    end,
    validator = function(data)
        return data.status and data.value and data.value >= 0 and data.value <= 100
    end
})

VCore.API:RegisterEndpoint('status:get', {
    handler = function(source, data)
        local Player = VCore.Functions.GetPlayer(source)
        if not Player then return nil end
        
        if data.status then
            return Player.data.status[data.status]
        end
        
        return Player.data.status
    end,
    cache = true,
    cacheDuration = 5000
})

-- Server Endpoints
VCore.API:RegisterEndpoint('server:info', {
    handler = function(source, data)
        return {
            name = GetConvar('sv_projectName', 'vCore Server'),
            version = VCore.Version,
            players = #GetPlayers(),
            maxPlayers = GetConvarInt('sv_maxclients', 32),
            uptime = os.time() - VCore.StartTime,
            framework = 'vCore'
        }
    end,
    cache = true,
    cacheDuration = 10000
})

VCore.API:RegisterEndpoint('server:players', {
    handler = function(source, data)
        local players = {}
        for src, player in pairs(VCore.ActivePlayers) do
            table.insert(players, {
                source = src,
                citizenid = player.citizenid,
                name = player.data.identity.fullName,
                profession = player.data.profession.primary,
                ping = GetPlayerPing(src)
            })
        end
        return players
    end,
    permissions = {'admin'},
    rateLimit = 'expensive'
})

-- ════════════════════════════════════════════════════════
-- EXPORTS SYSTEM
-- ════════════════════════════════════════════════════════

-- Core exports
exports('GetCoreObject', function()
    return VCore
end)

exports('GetAPI', function()
    return VCore.API
end)

-- Player exports
exports('GetPlayer', function(source)
    return VCore.Functions.GetPlayer(source)
end)

exports('GetPlayerByCitizenId', function(citizenid)
    return VCore.Functions.GetPlayerByCitizenId(citizenid)
end)

exports('GetPlayers', function()
    return VCore.Functions.GetPlayers()
end)

-- API call export
exports('APICall', function(source, endpoint, data)
    local promise = promise.new()
    
    VCore.API:Call(source, endpoint, data, function(result)
        promise:resolve(result)
    end)
    
    return Citizen.Await(promise)
end)

-- Currency exports
exports('AddCurrency', function(source, currency, amount, reason)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player:AddCurrency(currency, amount, reason)
end)

exports('RemoveCurrency', function(source, currency, amount, reason)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player:RemoveCurrency(currency, amount, reason)
end)

exports('GetCurrency', function(source, currency)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    return Player:GetCurrency(currency)
end)

-- Profession exports
exports('SetProfession', function(source, profession, level, isPrimary)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player:SetProfession(profession, level, isPrimary)
end)

exports('GetProfession', function(source)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.data.profession.primary
end)

-- Skill exports
exports('AddSkillXP', function(source, skill, amount)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player:AddSkillXP(skill, amount)
end)

exports('GetSkillLevel', function(source, skill)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    return Player:GetSkillLevel(skill)
end)

-- Status exports
exports('SetStatus', function(source, status, value)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return false end
    return Player:SetStatus(status, value)
end)

exports('GetStatus', function(source, status)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    return Player:GetStatus(status)
end)

-- ════════════════════════════════════════════════════════
-- CLIENT-SERVER COMMUNICATION
-- ════════════════════════════════════════════════════════

RegisterNetEvent('vCore:Server:APICall', function(endpoint, data, requestId)
    local src = source
    
    VCore.API:Call(src, endpoint, data, function(result)
        TriggerClientEvent('vCore:Client:APIResponse', src, requestId, result)
    end)
end)

-- ════════════════════════════════════════════════════════
-- BATCH OPERATIONS
-- ════════════════════════════════════════════════════════

VCore.API.Batch = {}

function VCore.API.Batch:Execute(source, operations, callback)
    local results = {}
    local completed = 0
    local total = #operations
    
    for i, op in ipairs(operations) do
        VCore.API:Call(source, op.endpoint, op.data, function(result)
            results[i] = result
            completed = completed + 1
            
            if completed == total then
                if callback then callback(results) end
            end
        end)
    end
end

RegisterNetEvent('vCore:Server:APIBatch', function(operations, requestId)
    local src = source
    
    VCore.API.Batch:Execute(src, operations, function(results)
        TriggerClientEvent('vCore:Client:APIBatchResponse', src, requestId, results)
    end)
end)

-- ════════════════════════════════════════════════════════
-- API DOCUMENTATION
-- ════════════════════════════════════════════════════════

function VCore.API:GetDocumentation()
    local docs = {
        version = self.Version,
        endpoints = {}
    }
    
    for name, ep in pairs(self.Endpoints) do
        docs.endpoints[name] = {
            name = name,
            rateLimit = ep.rateLimit,
            permissions = ep.permissions,
            cached = ep.cache,
            cacheDuration = ep.cacheDuration
        }
    end
    
    return docs
end

RegisterCommand('api:docs', function(source, args)
    if not VCore.Functions.HasPermission(source, 'admin') then return end
    
    local docs = VCore.API:GetDocumentation()
    print(json.encode(docs, {indent = true}))
end, false)

-- ════════════════════════════════════════════════════════
-- MONITORING & ANALYTICS
-- ════════════════════════════════════════════════════════

VCore.API.Analytics = {
    calls = {},
    errors = {},
    performance = {}
}

function VCore.API.Analytics:Track(endpoint, duration, success)
    if not self.calls[endpoint] then
        self.calls[endpoint] = {
            total = 0,
            success = 0,
            errors = 0,
            avgDuration = 0,
            maxDuration = 0
        }
    end
    
    local stats = self.calls[endpoint]
    stats.total = stats.total + 1
    
    if success then
        stats.success = stats.success + 1
    else
        stats.errors = stats.errors + 1
    end
    
    stats.avgDuration = (stats.avgDuration + duration) / 2
    stats.maxDuration = math.max(stats.maxDuration, duration)
end

function VCore.API.Analytics:GetReport()
    return {
        calls = self.calls,
        totalCalls = VCore.Shared.Table.Size(self.calls),
        rateLimit = VCore.API.RateLimiter.tracking
    }
end

-- Cache cleanup
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        
        local now = GetGameTimer()
        local cleared = 0
        
        for key, cached in pairs(VCore.API.Cache) do
            if now > cached.expires then
                VCore.API.Cache[key] = nil
                cleared = cleared + 1
            end
        end
        
        if cleared > 0 then
            VCore.Debug('Cleared ' .. cleared .. ' expired API cache entries')
        end
    end
end)

print('^2[vCore API]^7 Advanced API System Loaded')
print('^2[vCore API]^7 Version: ^3' .. VCore.API.Version)
print('^2[vCore API]^7 Endpoints: ^3' .. VCore.Shared.Table.Size(VCore.API.Endpoints))