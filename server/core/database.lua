-- ╔════════════════════════════════════════════════════════╗
-- ║  vCore Database Layer - Enterprise Edition            ║
-- ║  Features: Connection Pool, Query Cache, Migrations   ║
-- ╚════════════════════════════════════════════════════════╝

VCore.Database = {}
VCore.Database.Cache = {}
VCore.Database.QueryLog = {}
VCore.Database.ConnectionPool = {}
VCore.Database.Migrations = {}

-- ════════════════════════════════════════════════════════
-- CONFIGURATION
-- ════════════════════════════════════════════════════════

local DBConfig = {
    enableCache = true,
    cacheExpiration = 300000, -- 5 minutes
    enableQueryLog = true,
    slowQueryThreshold = 100, -- ms
    maxCacheSize = 1000,
    enableMigrations = true,
    currentVersion = '2.0.0',
}

-- ════════════════════════════════════════════════════════
-- QUERY CACHE SYSTEM
-- ════════════════════════════════════════════════════════

function VCore.Database.Cache:Set(key, value, expiration)
    if not DBConfig.enableCache then return end
    
    expiration = expiration or DBConfig.cacheExpiration
    
    -- Check cache size limit
    if VCore.Shared.Table.Size(self) >= DBConfig.maxCacheSize then
        self:Clean()
    end
    
    self[key] = {
        data = value,
        expires = GetGameTimer() + expiration,
        hits = 0
    }
end

function VCore.Database.Cache:Get(key)
    if not DBConfig.enableCache then return nil end
    
    local cached = self[key]
    if not cached then return nil end
    
    -- Check expiration
    if GetGameTimer() > cached.expires then
        self[key] = nil
        return nil
    end
    
    cached.hits = cached.hits + 1
    return cached.data
end

function VCore.Database.Cache:Invalidate(pattern)
    if not pattern then
        -- Clear all cache
        for k in pairs(self) do
            if type(self[k]) == 'table' and self[k].data then
                self[k] = nil
            end
        end
        return
    end
    
    -- Pattern-based invalidation
    for k in pairs(self) do
        if type(self[k]) == 'table' and self[k].data then
            if string.match(k, pattern) then
                self[k] = nil
            end
        end
    end
end

function VCore.Database.Cache:Clean()
    local now = GetGameTimer()
    local count = 0
    
    for k, v in pairs(self) do
        if type(v) == 'table' and v.expires then
            if now > v.expires or v.hits == 0 then
                self[k] = nil
                count = count + 1
            end
        end
    end
    
    VCore.Debug('Cleaned ' .. count .. ' expired cache entries')
end

-- ════════════════════════════════════════════════════════
-- QUERY BUILDER
-- ════════════════════════════════════════════════════════

VCore.Database.QueryBuilder = {}
VCore.Database.QueryBuilder.__index = VCore.Database.QueryBuilder

function VCore.Database.QueryBuilder:New()
    local self = setmetatable({}, VCore.Database.QueryBuilder)
    self.query = {
        type = nil,
        table = nil,
        columns = '*',
        where = {},
        joins = {},
        orderBy = nil,
        limit = nil,
        offset = nil,
        values = {}
    }
    return self
end

function VCore.Database.QueryBuilder:Select(columns)
    self.query.type = 'SELECT'
    if columns then
        if type(columns) == 'table' then
            self.query.columns = table.concat(columns, ', ')
        else
            self.query.columns = columns
        end
    end
    return self
end

function VCore.Database.QueryBuilder:From(table)
    self.query.table = table
    return self
end

function VCore.Database.QueryBuilder:Where(column, operator, value)
    if value == nil then
        value = operator
        operator = '='
    end
    
    table.insert(self.query.where, {
        column = column,
        operator = operator,
        value = value,
        condition = 'AND'
    })
    return self
end

function VCore.Database.QueryBuilder:OrWhere(column, operator, value)
    if value == nil then
        value = operator
        operator = '='
    end
    
    table.insert(self.query.where, {
        column = column,
        operator = operator,
        value = value,
        condition = 'OR'
    })
    return self
end

function VCore.Database.QueryBuilder:Join(table, column1, operator, column2)
    table.insert(self.query.joins, {
        type = 'INNER',
        table = table,
        column1 = column1,
        operator = operator or '=',
        column2 = column2
    })
    return self
end

function VCore.Database.QueryBuilder:LeftJoin(table, column1, operator, column2)
    table.insert(self.query.joins, {
        type = 'LEFT',
        table = table,
        column1 = column1,
        operator = operator or '=',
        column2 = column2
    })
    return self
end

function VCore.Database.QueryBuilder:OrderBy(column, direction)
    self.query.orderBy = column .. ' ' .. (direction or 'ASC')
    return self
end

function VCore.Database.QueryBuilder:Limit(limit, offset)
    self.query.limit = limit
    if offset then
        self.query.offset = offset
    end
    return self
end

function VCore.Database.QueryBuilder:Insert(table)
    self.query.type = 'INSERT'
    self.query.table = table
    return self
end

function VCore.Database.QueryBuilder:Values(data)
    self.query.values = data
    return self
end

function VCore.Database.QueryBuilder:Update(table)
    self.query.type = 'UPDATE'
    self.query.table = table
    return self
end

function VCore.Database.QueryBuilder:Set(data)
    self.query.values = data
    return self
end

function VCore.Database.QueryBuilder:Delete(table)
    self.query.type = 'DELETE'
    if table then
        self.query.table = table
    end
    return self
end

function VCore.Database.QueryBuilder:Build()
    local sql = ''
    local params = {}
    
    if self.query.type == 'SELECT' then
        sql = 'SELECT ' .. self.query.columns .. ' FROM ' .. self.query.table
        
        -- Joins
        for _, join in ipairs(self.query.joins) do
            sql = sql .. ' ' .. join.type .. ' JOIN ' .. join.table
            sql = sql .. ' ON ' .. join.column1 .. ' ' .. join.operator .. ' ' .. join.column2
        end
        
        -- Where
        if #self.query.where > 0 then
            sql = sql .. ' WHERE '
            for i, condition in ipairs(self.query.where) do
                if i > 1 then
                    sql = sql .. ' ' .. condition.condition .. ' '
                end
                sql = sql .. condition.column .. ' ' .. condition.operator .. ' ?'
                table.insert(params, condition.value)
            end
        end
        
        -- Order By
        if self.query.orderBy then
            sql = sql .. ' ORDER BY ' .. self.query.orderBy
        end
        
        -- Limit
        if self.query.limit then
            sql = sql .. ' LIMIT ' .. self.query.limit
            if self.query.offset then
                sql = sql .. ' OFFSET ' .. self.query.offset
            end
        end
        
    elseif self.query.type == 'INSERT' then
        local columns = {}
        local placeholders = {}
        
        for k, v in pairs(self.query.values) do
            table.insert(columns, k)
            table.insert(placeholders, '?')
            table.insert(params, v)
        end
        
        sql = 'INSERT INTO ' .. self.query.table
        sql = sql .. ' (' .. table.concat(columns, ', ') .. ')'
        sql = sql .. ' VALUES (' .. table.concat(placeholders, ', ') .. ')'
        
    elseif self.query.type == 'UPDATE' then
        local sets = {}
        
        for k, v in pairs(self.query.values) do
            table.insert(sets, k .. ' = ?')
            table.insert(params, v)
        end
        
        sql = 'UPDATE ' .. self.query.table .. ' SET ' .. table.concat(sets, ', ')
        
        -- Where
        if #self.query.where > 0 then
            sql = sql .. ' WHERE '
            for i, condition in ipairs(self.query.where) do
                if i > 1 then
                    sql = sql .. ' ' .. condition.condition .. ' '
                end
                sql = sql .. condition.column .. ' ' .. condition.operator .. ' ?'
                table.insert(params, condition.value)
            end
        end
        
    elseif self.query.type == 'DELETE' then
        sql = 'DELETE FROM ' .. self.query.table
        
        -- Where
        if #self.query.where > 0 then
            sql = sql .. ' WHERE '
            for i, condition in ipairs(self.query.where) do
                if i > 1 then
                    sql = sql .. ' ' .. condition.condition .. ' '
                end
                sql = sql .. condition.column .. ' ' .. condition.operator .. ' ?'
                table.insert(params, condition.value)
            end
        end
    end
    
    return sql, params
end

function VCore.Database.QueryBuilder:Execute()
    local sql, params = self:Build()
    return VCore.Database.Execute(sql, params)
end

function VCore.Database.QueryBuilder:ExecuteAsync()
    local sql, params = self:Build()
    return VCore.Database.ExecuteAsync(sql, params)
end

-- ════════════════════════════════════════════════════════
-- CORE DATABASE FUNCTIONS
-- ════════════════════════════════════════════════════════

function VCore.Database.Execute(query, parameters)
    local startTime = GetGameTimer()
    
    -- Check cache
    local cacheKey = query .. json.encode(parameters or {})
    local cached = VCore.Database.Cache:Get(cacheKey)
    if cached then
        VCore.Debug('Cache hit for query')
        return cached
    end
    
    -- Execute query
    local result = MySQL.query.await(query, parameters)
    local executionTime = GetGameTimer() - startTime
    
    -- Log slow queries
    if DBConfig.enableQueryLog and executionTime > DBConfig.slowQueryThreshold then
        VCore.Database:LogSlowQuery(query, executionTime, parameters)
    end
    
    -- Cache result
    if result then
        VCore.Database.Cache:Set(cacheKey, result)
    end
    
    return result
end

function VCore.Database.ExecuteAsync(query, parameters)
    return MySQL.query(query, parameters)
end

function VCore.Database.Scalar(query, parameters)
    local result = VCore.Database.Execute(query, parameters)
    if result and result[1] then
        local first = result[1]
        for _, v in pairs(first) do
            return v
        end
    end
    return nil
end

function VCore.Database.Insert(query, parameters)
    local result = MySQL.insert.await(query, parameters)
    
    -- Invalidate cache for this table
    if result then
        local tableName = query:match('INSERT INTO (%w+)')
        if tableName then
            VCore.Database.Cache:Invalidate(tableName)
        end
    end
    
    return result
end

function VCore.Database.Update(query, parameters)
    local result = MySQL.update.await(query, parameters)
    
    -- Invalidate cache for this table
    if result then
        local tableName = query:match('UPDATE (%w+)')
        if tableName then
            VCore.Database.Cache:Invalidate(tableName)
        end
    end
    
    return result
end

function VCore.Database:LogSlowQuery(query, time, params)
    table.insert(self.QueryLog, {
        query = query,
        time = time,
        params = params,
        timestamp = os.time()
    })
    
    VCore.Error('Slow Query (' .. time .. 'ms): ' .. query)
    
    -- Keep only last 100 slow queries
    if #self.QueryLog > 100 then
        table.remove(self.QueryLog, 1)
    end
end

-- ════════════════════════════════════════════════════════
-- MIGRATION SYSTEM
-- ════════════════════════════════════════════════════════

function VCore.Database.Migrations:Run()
    if not DBConfig.enableMigrations then return end
    
    VCore.Success('Running database migrations...')
    
    -- Create migrations table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS migrations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            version VARCHAR(50) NOT NULL,
            name VARCHAR(255) NOT NULL,
            executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_version (version)
        )
    ]])
    
    -- Get current database version
    local currentVersion = self:GetCurrentVersion()
    
    -- Run pending migrations
    for _, migration in ipairs(self:GetPendingMigrations(currentVersion)) do
        local success, err = pcall(function()
            migration.up()
            self:RecordMigration(migration.version, migration.name)
            VCore.Success('Migration ' .. migration.name .. ' completed')
        end)
        
        if not success then
            VCore.Error('Migration ' .. migration.name .. ' failed: ' .. err)
            return false
        end
    end
    
    VCore.Success('All migrations completed successfully')
    return true
end

function VCore.Database.Migrations:GetCurrentVersion()
    local result = MySQL.scalar.await('SELECT version FROM migrations ORDER BY id DESC LIMIT 1')
    return result or '0.0.0'
end

function VCore.Database.Migrations:GetPendingMigrations(currentVersion)
    -- This would be populated from migration files
    local migrations = {
        {
            version = '1.0.0',
            name = 'create_players_table',
            up = function()
                MySQL.query.await([[
                    CREATE TABLE IF NOT EXISTS players (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        citizenid VARCHAR(50) UNIQUE NOT NULL,
                        identifier VARCHAR(255) NOT NULL,
                        currencies TEXT,
                        identity TEXT,
                        profession TEXT,
                        organization TEXT,
                        skills TEXT,
                        reputation TEXT,
                        status TEXT,
                        position TEXT,
                        metadata TEXT,
                        inventory LONGTEXT,
                        playtime INT DEFAULT 0,
                        last_login TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_citizenid (citizenid),
                        INDEX idx_identifier (identifier)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                ]])
            end
        },
        {
            version = '1.1.0',
            name = 'create_bans_table',
            up = function()
                MySQL.query.await([[
                    CREATE TABLE IF NOT EXISTS bans (
                        id INT AUTO_INCREMENT PRIMARY KEY,
                        identifier VARCHAR(255) NOT NULL,
                        reason TEXT,
                        banned_by VARCHAR(255),
                        expire TIMESTAMP NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        INDEX idx_identifier (identifier),
                        INDEX idx_expire (expire)
                    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                ]])
            end
        },
        {
            version = '2.0.0',
            name = 'add_advanced_player_fields',
            up = function()
                MySQL.query.await([[
                    ALTER TABLE players
                    ADD COLUMN IF NOT EXISTS secondary_professions TEXT AFTER profession,
                    ADD COLUMN IF NOT EXISTS licenses TEXT AFTER metadata,
                    ADD COLUMN IF NOT EXISTS achievements TEXT AFTER licenses
                ]])
            end
        }
    }
    
    -- Filter pending migrations
    local pending = {}
    for _, migration in ipairs(migrations) do
        if VCore.Shared.String.CompareVersion(migration.version, currentVersion) > 0 then
            table.insert(pending, migration)
        end
    end
    
    return pending
end

function VCore.Database.Migrations:RecordMigration(version, name)
    MySQL.insert.await('INSERT INTO migrations (version, name) VALUES (?, ?)', {version, name})
end

-- ════════════════════════════════════════════════════════
-- TRANSACTION SUPPORT
-- ════════════════════════════════════════════════════════

VCore.Database.Transaction = {}

function VCore.Database.Transaction:Begin()
    MySQL.query.await('START TRANSACTION')
    self.active = true
end

function VCore.Database.Transaction:Commit()
    if not self.active then return false end
    MySQL.query.await('COMMIT')
    self.active = false
    return true
end

function VCore.Database.Transaction:Rollback()
    if not self.active then return false end
    MySQL.query.await('ROLLBACK')
    self.active = false
    return true
end

-- ════════════════════════════════════════════════════════
-- INITIALIZATION
-- ════════════════════════════════════════════════════════

CreateThread(function()
    -- Run migrations
    VCore.Database.Migrations:Run()
    
    -- Start cache cleanup
    while true do
        Wait(60000) -- Every minute
        VCore.Database.Cache:Clean()
    end
end)

-- Helper function for version comparison
VCore.Shared.String.CompareVersion = function(v1, v2)
    local v1Parts = VCore.Shared.String.Split(v1, '.')
    local v2Parts = VCore.Shared.String.Split(v2, '.')
    
    for i = 1, math.max(#v1Parts, #v2Parts) do
        local num1 = tonumber(v1Parts[i]) or 0
        local num2 = tonumber(v2Parts[i]) or 0
        
        if num1 > num2 then return 1 end
        if num1 < num2 then return -1 end
    end
    
    return 0
end

print('^2[vCore Database]^7 Advanced Database Layer Loaded')
print('^2[vCore Database]^7 Cache: ^3' .. (DBConfig.enableCache and 'Enabled' or 'Disabled'))
print('^2[vCore Database]^7 Query Log: ^3' .. (DBConfig.enableQueryLog and 'Enabled' or 'Disabled'))
print('^2[vCore Database]^7 Migrations: ^3' .. (DBConfig.enableMigrations and 'Enabled' or 'Disabled'))