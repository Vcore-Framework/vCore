-- ╔════════════════════════════════════════════════════════╗
-- ║  vCore Session Management - Enterprise Edition         ║
-- ║  Features: Auto-save, AFK Detection, State Persistence║
-- ╚════════════════════════════════════════════════════════╝

VCore.Session = {}
VCore.Session.Active = {}
VCore.Session.Config = {
    autoSaveInterval = 300000, -- 5 minutes
    afkTimeout = 900000, -- 15 minutes
    disconnectGracePeriod = 30000, -- 30 seconds
    enableStateRecovery = true,
    maxSessions = 1, -- Max sessions per player
}

-- ════════════════════════════════════════════════════════
-- SESSION CLASS
-- ════════════════════════════════════════════════════════

VCore.SessionClass = {}
VCore.SessionClass.__index = VCore.SessionClass

function VCore.SessionClass:New(player)
    local self = setmetatable({}, VCore.SessionClass)
    
    self.player = player
    self.sessionId = VCore.Shared.GenerateId.SerialNumber()
    self.startTime = os.time()
    self.lastSaveTime = os.time()
    self.lastActivityTime = os.time()
    self.isActive = true
    self.afkWarned = false
    
    -- Session state
    self.state = {
        position = player.data.position,
        health = 200,
        armor = 0,
        weapon = nil,
        vehicle = nil,
        routing = 0
    }
    
    -- Activity tracking
    self.activity = {
        totalMovement = 0,
        lastPosition = player.data.position,
        keyPresses = 0,
        chatMessages = 0
    }
    
    -- Performance metrics
    self.metrics = {
        avgPing = 0,
        maxPing = 0,
        packetLoss = 0,
        fps = 0
    }
    
    VCore.Session.Active[player.source] = self
    
    return self
end

-- ════════════════════════════════════════════════════════
-- ACTIVITY TRACKING
-- ════════════════════════════════════════════════════════

function VCore.SessionClass:UpdateActivity(activityType)
    self.lastActivityTime = os.time()
    self.afkWarned = false
    
    -- Track specific activity
    if activityType == 'movement' then
        self.activity.totalMovement = self.activity.totalMovement + 1
    elseif activityType == 'keypress' then
        self.activity.keyPresses = self.activity.keyPresses + 1
    elseif activityType == 'chat' then
        self.activity.chatMessages = self.activity.chatMessages + 1
    end
    
    -- Update player state if AFK
    if self.player:IsState(VCore.PlayerStates.AFK) then
        self.player:SetState(VCore.PlayerStates.ACTIVE)
    end
end

function VCore.SessionClass:CheckAFK()
    local timeSinceActivity = os.time() - self.lastActivityTime
    
    if timeSinceActivity >= (VCore.Session.Config.afkTimeout / 1000) then
        if not self.player:IsState(VCore.PlayerStates.AFK) then
            self.player:SetState(VCore.PlayerStates.AFK)
            self.player:Notify('You are now AFK', 'inform')
            TriggerEvent('vCore:Server:PlayerAFK', self.player.source, true)
        end
        return true
    elseif timeSinceActivity >= ((VCore.Session.Config.afkTimeout / 1000) - 60) and not self.afkWarned then
        -- Warn 1 minute before AFK
        self.player:Notify('You will be marked AFK in 1 minute', 'warning')
        self.afkWarned = true
    end
    
    return false
end

-- ════════════════════════════════════════════════════════
-- STATE MANAGEMENT
-- ════════════════════════════════════════════════════════

function VCore.SessionClass:SaveState()
    local ped = GetPlayerPed(self.player.source)
    
    self.state.position = GetEntityCoords(ped)
    self.state.health = GetEntityHealth(ped)
    self.state.armor = GetPedArmour(ped)
    self.state.weapon = GetSelectedPedWeapon(ped)
    
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        self.state.vehicle = {
            model = GetEntityModel(vehicle),
            plate = GetVehicleNumberPlateText(vehicle),
            coords = GetEntityCoords(vehicle),
            heading = GetEntityHeading(vehicle),
            health = GetVehicleEngineHealth(vehicle),
            bodyHealth = GetVehicleBodyHealth(vehicle),
            fuel = GetVehicleFuelLevel(vehicle)
        }
    else
        self.state.vehicle = nil
    end
    
    -- Save to database for crash recovery
    if VCore.Session.Config.enableStateRecovery then
        MySQL.update('UPDATE player_sessions SET state = ?, last_update = ? WHERE session_id = ?', {
            json.encode(self.state),
            os.time(),
            self.sessionId
        })
    end
end

function VCore.SessionClass:RestoreState()
    if not VCore.Session.Config.enableStateRecovery then return false end
    
    local result = MySQL.query.await('SELECT state FROM player_sessions WHERE citizenid = ? ORDER BY last_update DESC LIMIT 1', {
        self.player.citizenid
    })
    
    if result and result[1] and result[1].state then
        local state = json.decode(result[1].state)
        
        -- Restore position
        SetEntityCoords(GetPlayerPed(self.player.source), state.position.x, state.position.y, state.position.z)
        
        -- Restore health and armor
        SetEntityHealth(GetPlayerPed(self.player.source), state.health)
        SetPedArmour(GetPlayerPed(self.player.source), state.armor)
        
        -- Restore vehicle if applicable
        if state.vehicle then
            TriggerClientEvent('vCore:Client:RestoreVehicle', self.player.source, state.vehicle)
        end
        
        VCore.Success('Restored session state for ' .. self.player.citizenid)
        return true
    end
    
    return false
end

-- ════════════════════════════════════════════════════════
-- PERFORMANCE METRICS
-- ════════════════════════════════════════════════════════

function VCore.SessionClass:UpdateMetrics(ping, packetLoss, fps)
    self.metrics.avgPing = (self.metrics.avgPing + ping) / 2
    self.metrics.maxPing = math.max(self.metrics.maxPing, ping)
    self.metrics.packetLoss = packetLoss
    self.metrics.fps = fps
    
    -- Alert on poor performance
    if ping > 300 or packetLoss > 5 then
        if not self.performanceWarned then
            self.player:Notify('Poor network connection detected', 'warning')
            self.performanceWarned = true
        end
    else
        self.performanceWarned = false
    end
end

function VCore.SessionClass:GetMetrics()
    return {
        avgPing = math.floor(self.metrics.avgPing),
        maxPing = self.metrics.maxPing,
        packetLoss = self.metrics.packetLoss,
        fps = self.metrics.fps,
        playtime = os.time() - self.startTime,
        activity = self.activity
    }
end

-- ════════════════════════════════════════════════════════
-- AUTO-SAVE SYSTEM
-- ════════════════════════════════════════════════════════

function VCore.SessionClass:AutoSave()
    if not self.isActive then return end
    
    local timeSinceLastSave = os.time() - self.lastSaveTime
    
    if timeSinceLastSave >= (VCore.Session.Config.autoSaveInterval / 1000) then
        self:Save()
    end
end

function VCore.SessionClass:Save()
    self:SaveState()
    self.player:Save()
    self.lastSaveTime = os.time()
    
    VCore.Debug('Auto-saved session for ' .. self.player.citizenid)
end

-- ════════════════════════════════════════════════════════
-- SESSION TERMINATION
-- ════════════════════════════════════════════════════════

function VCore.SessionClass:End(reason)
    reason = reason or 'disconnect'
    
    -- Final save
    self:Save()
    
    -- Calculate playtime
    local playtime = os.time() - self.startTime
    self.player.data.statistics.playtime = self.player.data.statistics.playtime + playtime
    
    -- Log session
    MySQL.insert('INSERT INTO session_logs (citizenid, session_id, start_time, end_time, duration, reason, metrics) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        self.player.citizenid,
        self.sessionId,
        self.startTime,
        os.time(),
        playtime,
        reason,
        json.encode(self.metrics)
    })
    
    -- Mark inactive
    self.isActive = false
    
    -- Remove from active sessions
    VCore.Session.Active[self.player.source] = nil
    
    VCore.Debug('Session ended for ' .. self.player.citizenid .. ' (Reason: ' .. reason .. ', Duration: ' .. playtime .. 's)')
end

-- ════════════════════════════════════════════════════════
-- SESSION MANAGER
-- ════════════════════════════════════════════════════════

function VCore.Session:Create(player)
    -- Check for existing sessions
    local existing = self:GetByIdentifier(player.data.identifier)
    if existing then
        if self.Config.maxSessions == 1 then
            existing:End('new_session')
        end
    end
    
    -- Create new session
    local session = VCore.SessionClass:New(player)
    
    -- Record in database
    MySQL.insert('INSERT INTO player_sessions (citizenid, session_id, identifier, start_time, ip, state) VALUES (?, ?, ?, ?, ?, ?)', {
        player.citizenid,
        session.sessionId,
        player.data.identifier,
        os.time(),
        player.data.ip,
        json.encode(session.state)
    })
    
    TriggerEvent('vCore:Server:SessionCreated', player.source, session.sessionId)
    
    return session
end

function VCore.Session:Get(source)
    return self.Active[source]
end

function VCore.Session:GetByIdentifier(identifier)
    for source, session in pairs(self.Active) do
        if session.player.data.identifier == identifier then
            return session
        end
    end
    return nil
end

function VCore.Session:UpdateAll()
    for source, session in pairs(self.Active) do
        if session.isActive then
            session:CheckAFK()
            session:AutoSave()
        end
    end
end

-- ════════════════════════════════════════════════════════
-- PLAYER CLASS INTEGRATION
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:CreateSession()
    self.session = VCore.Session:Create(self)
    return self.session
end

function VCore.PlayerClass:GetSession()
    return self.session or VCore.Session:Get(self.source)
end

function VCore.PlayerClass:Save()
    -- Save player data to database
    local query = [[
        UPDATE players SET
            currencies = ?,
            identity = ?,
            profession = ?,
            organization = ?,
            skills = ?,
            reputation = ?,
            status = ?,
            position = ?,
            metadata = ?,
            inventory = ?,
            licenses = ?,
            settings = ?,
            statistics = ?,
            session = ?,
            updated_at = NOW()
        WHERE citizenid = ?
    ]]
    
    MySQL.update(query, {
        json.encode(self.data.wallet),
        json.encode(self.data.identity),
        json.encode(self.data.profession),
        json.encode(self.data.organization),
        json.encode(self.data.skills),
        json.encode(self.data.reputation),
        json.encode(self.data.status),
        json.encode(self.data.position),
        json.encode(self.data.metadata),
        json.encode(self.data.inventory),
        json.encode(self.data.licenses),
        json.encode(self.data.settings),
        json.encode(self.data.statistics),
        json.encode(self.data.session),
        self.citizenid
    })
    
    self.data.session.lastSave = os.time()
    
    TriggerEvent('vCore:Server:PlayerSaved', self.source, self.citizenid)
    VCore.Debug('Saved player: ' .. self.citizenid)
end

function VCore.PlayerClass:Load(citizenid)
    local result = MySQL.query.await('SELECT * FROM players WHERE citizenid = ?', {citizenid})
    
    if not result or not result[1] then
        VCore.Error('Failed to load player: ' .. citizenid)
        return false
    end
    
    local data = result[1]
    
    -- Deserialize JSON fields
    self.data.wallet = json.decode(data.currencies) or self.data.wallet
    self.data.identity = json.decode(data.identity) or self.data.identity
    self.data.profession = json.decode(data.profession) or self.data.profession
    self.data.organization = json.decode(data.organization) or self.data.organization
    self.data.skills = json.decode(data.skills) or self.data.skills
    self.data.reputation = json.decode(data.reputation) or self.data.reputation
    self.data.status = json.decode(data.status) or self.data.status
    self.data.position = json.decode(data.position) or self.data.position
    self.data.metadata = json.decode(data.metadata) or self.data.metadata
    self.data.inventory = json.decode(data.inventory) or self.data.inventory
    self.data.licenses = json.decode(data.licenses) or self.data.licenses
    self.data.settings = json.decode(data.settings) or self.data.settings
    self.data.statistics = json.decode(data.statistics) or self.data.statistics
    self.data.session = json.decode(data.session) or self.data.session
    
    -- Update session info
    self.data.session.lastLogin = os.time()
    self.data.session.loginCount = (self.data.session.loginCount or 0) + 1
    
    -- Add IP to history
    if not VCore.Shared.Table.Contains(self.data.session.ipHistory or {}, self.data.ip) then
        table.insert(self.data.session.ipHistory, self.data.ip)
    end
    
    VCore.Success('Loaded player: ' .. self.citizenid)
    TriggerEvent('vCore:Server:PlayerLoaded', self.source, self)
    
    return true
end

function VCore.PlayerClass:Logout()
    -- End session
    if self.session then
        self.session:End('logout')
    end
    
    -- Final save
    self:Save()
    
    -- Clear from active players
    VCore.ActivePlayers[self.source] = nil
    
    -- Notify
    TriggerClientEvent('vCore:Client:OnPlayerUnload', self.source)
    TriggerEvent('vCore:Server:PlayerLogout', self.source, self.citizenid)
    
    VCore.Debug('Player logged out: ' .. self.citizenid)
end

-- ════════════════════════════════════════════════════════
-- BACKGROUND TASKS
-- ════════════════════════════════════════════════════════

CreateThread(function()
    while true do
        Wait(30000) -- Every 30 seconds
        
        -- Update all active sessions
        VCore.Session:UpdateAll()
    end
end)

CreateThread(function()
    while true do
        Wait(VCore.Session.Config.autoSaveInterval)
        
        -- Save all active players
        for source, player in pairs(VCore.ActivePlayers) do
            local session = player:GetSession()
            if session and session.isActive then
                session:Save()
            end
        end
        
        VCore.Debug('Auto-save completed for ' .. VCore.Shared.Table.Size(VCore.ActivePlayers) .. ' players')
    end
end)

-- Client to Server communication
RegisterNetEvent('vCore:Server:UpdateActivity', function(activityType)
    local src = source
    local session = VCore.Session:Get(src)
    
    if session then
        session:UpdateActivity(activityType)
    end
end)

RegisterNetEvent('vCore:Server:UpdateMetrics', function(ping, packetLoss, fps)
    local src = source
    local session = VCore.Session:Get(src)
    
    if session then
        session:UpdateMetrics(ping, packetLoss, fps)
    end
end)

print('^2[vCore Session]^7 Advanced Session Management Loaded')
print('^2[vCore Session]^7 Auto-save: Every ' .. (VCore.Session.Config.autoSaveInterval / 1000) .. ' seconds')
print('^2[vCore Session]^7 AFK Timeout: ' .. (VCore.Session.Config.afkTimeout / 1000) .. ' seconds')