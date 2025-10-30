-- ┌─────────────────────────────────────────────────────────┐
-- │ vCore Player System - Unique Architecture                │
-- │ Different from QB/ESX with profession & organization     │
-- └─────────────────────────────────────────────────────────┘

VCore.Players = {}
VCore.PlayerCount = 0

-- ════════════════════════════════════════════════════════
-- CREATE PLAYER OBJECT
-- ════════════════════════════════════════════════════════

VCore.Functions.CreatePlayer = function(source, citizenid)
    local self = {}
    local src = source
    
    -- ═══ PLAYER DATA STRUCTURE (Unique to vCore) ═══
    self.PlayerData = {
        source = src,
        citizenid = citizenid or VCore.Shared.GenerateId.CitizenId(),
        identifier = VCore.Functions.GetIdentifier(src, 'license'),
        steam = VCore.Functions.GetIdentifier(src, 'steam'),
        discord = VCore.Functions.GetIdentifier(src, 'discord'),
        
        -- Identity
        firstName = '',
        lastName = '',
        dob = '',
        sex = '',
        nationality = 'USA',
        height = 180,
        phone = VCore.Shared.GenerateId.PhoneNumber(),
        
        -- Financial
        currencies = {},
        bankAccount = VCore.Shared.GenerateId.BankAccount(),
        
        -- Profession System (Not "job")
        profession = nil,
        secondaryProfessions = {},
        
        -- Organization System (Not "gang")
        organization = nil,
        
        -- Skills System (Unique RPG progression)
        skills = {},
        
        -- Reputation System (Unique faction system)
        reputation = {},
        
        -- Status Effects
        status = {
            hunger = 100,
            thirst = 100,
            stress = 0,
            energy = 100,
            hygiene = 100,
        },
        
        -- Player State
        isDead = false,
        inLastStand = false,
        isHandcuffed = false,
        armor = 0,
        position = Config.Spawn.DefaultCoords,
        
        -- Metadata
        bloodType = VCore.Shared.BloodTypes[math.random(#VCore.Shared.BloodTypes)],
        fingerprint = VCore.Shared.GenerateId.Fingerprint(),
        walletId = VCore.Shared.GenerateId.WalletId(),
        callsign = 'NONE',
        
        -- Licenses
        licenses = {},
        
        -- Inventory
        inventory = {},
        maxWeight = 30000,
        
        -- Session
        lastSave = os.time(),
        playTime = 0,
        lastLogin = os.time(),
    }
    
    -- Initialize currencies
    for currency, data in pairs(Config.Wallet.Currencies) do
        self.PlayerData.currencies[currency] = Config.Wallet.StartingMoney[currency] or 0
    end
    
    -- Initialize skills
    for skill, _ in pairs(Config.Skills.Types) do
        self.PlayerData.skills[skill] = {level = 0, xp = 0}
    end
    
    -- Initialize reputation
    for faction, _ in pairs(Config.Reputation.Factions) do
        self.PlayerData.reputation[faction] = 0
    end
    
    -- ═══ PLAYER METHODS ═══
    self.Functions = {}
    
    -- Update client data
    self.Functions.UpdatePlayerData = function()
        TriggerClientEvent('vCore:Client:OnPlayerLoaded', src)
        TriggerClientEvent('vCore:Player:SetPlayerData', src, self.PlayerData)
    end
    
    -- ═══ PROFESSION MANAGEMENT ═══
    self.Functions.SetProfession = function(professionName, level, isPrimary)
        level = tonumber(level) or 0
        
        if not Config.Professions.Types[professionName] then
            VCore.Error('Invalid profession:', professionName)
            return false
        end
        
        local professionData = Config.Professions.Types[professionName]
        
        if isPrimary or not self.PlayerData.profession then
            self.PlayerData.profession = {
                name = professionName,
                label = professionData.label,
                level = level,
                rank = 'Employee', -- You can add rank system
                salary = professionData.salary,
                onDuty = false,
                isBoss = false,
                skills = professionData.skills,
            }
            
            TriggerClientEvent('vCore:Client:OnProfessionUpdate', src, self.PlayerData.profession)
        else
            -- Add as secondary profession
            if Config.Professions.EnableMultipleProfessions then
                table.insert(self.PlayerData.secondaryProfessions, {
                    name = professionName,
                    label = professionData.label,
                    level = level,
                })
            end
        end
        
        self.Functions.UpdatePlayerData()
        return true
    end
    
    self.Functions.GetProfession = function()
        return self.PlayerData.profession
    end
    
    self.Functions.SetDuty = function(onDuty)
        if not self.PlayerData.profession then return false end
        
        self.PlayerData.profession.onDuty = onDuty
        TriggerClientEvent('vCore:Client:OnDutyUpdate', src, onDuty)
        self.Functions.UpdatePlayerData()
        return true
    end
    
    -- ═══ ORGANIZATION MANAGEMENT ═══
    self.Functions.SetOrganization = function(orgName, level, isLeader)
        level = tonumber(level) or 0
        
        self.PlayerData.organization = {
            name = orgName,
            label = orgName,
            level = level,
            rank = 'Member',
            isLeader = isLeader or false,
        }
        
        TriggerClientEvent('vCore:Client:OnOrganizationUpdate', src, self.PlayerData.organization)
        self.Functions.UpdatePlayerData()
        return true
    end
    
    -- ═══ CURRENCY MANAGEMENT ═══
    self.Functions.AddCurrency = function(currency, amount, reason)
        reason = reason or 'unknown'
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not self.PlayerData.currencies[currency] then return false end
        
        -- Check max cash limit
        if currency == 'cash' and Config.Wallet.MaxCash then
            local newAmount = self.PlayerData.currencies[currency] + amount
            if newAmount > Config.Wallet.MaxCash then
                VCore.Functions.Notify(src, 'You cannot carry more than $' .. Config.Wallet.MaxCash, 'error')
                return false
            end
        end
        
        self.PlayerData.currencies[currency] = self.PlayerData.currencies[currency] + amount
        self.Functions.UpdatePlayerData()
        
        TriggerEvent('vCore:Server:MoneyLog', src, currency, amount, 'add', reason)
        return true
    end
    
    self.Functions.RemoveCurrency = function(currency, amount, reason)
        reason = reason or 'unknown'
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not self.PlayerData.currencies[currency] then return false end
        
        local currencyData = Config.Wallet.Currencies[currency]
        
        -- Check if currency can go negative
        if currencyData and not currencyData.canDrop then
            if (self.PlayerData.currencies[currency] - amount) < 0 then
                return false
            end
        end
        
        self.PlayerData.currencies[currency] = self.PlayerData.currencies[currency] - amount
        self.Functions.UpdatePlayerData()
        
        TriggerEvent('vCore:Server:MoneyLog', src, currency, amount, 'remove', reason)
        return true
    end
    
    self.Functions.SetCurrency = function(currency, amount, reason)
        reason = reason or 'unknown'
        amount = tonumber(amount)
        
        if amount < 0 then return false end
        if not self.PlayerData.currencies[currency] then return false end
        
        self.PlayerData.currencies[currency] = amount
        self.Functions.UpdatePlayerData()
        return true
    end
    
    self.Functions.GetCurrency = function(currency)
        if not currency then return nil end
        return self.PlayerData.currencies[currency] or 0
    end
    
    self.Functions.GetAllCurrencies = function()
        return self.PlayerData.currencies
    end
    
    -- ═══ SKILL SYSTEM ═══
    self.Functions.AddSkillXP = function(skill, xp)
        if not self.PlayerData.skills[skill] then return false end
        
        xp = xp * (Config.Skills.ExperienceMultiplier or 1.0)
        self.PlayerData.skills[skill].xp = self.PlayerData.skills[skill].xp + xp
        
        -- Level up calculation (1000 XP per level)
        local xpRequired = self.PlayerData.skills[skill].level * 1000
        
        if self.PlayerData.skills[skill].xp >= xpRequired and self.PlayerData.skills[skill].level < Config.Skills.MaxLevel then
            self.PlayerData.skills[skill].level = self.PlayerData.skills[skill].level + 1
            self.PlayerData.skills[skill].xp = 0
            
            VCore.Functions.Notify(src, 'Skill Level Up! ' .. Config.Skills.Types[skill].label .. ' is now level ' .. self.PlayerData.skills[skill].level, 'success')
            TriggerEvent('vCore:Server:SkillLevelUp', src, skill, self.PlayerData.skills[skill].level)
        end
        
        self.Functions.UpdatePlayerData()
        return true
    end
    
    self.Functions.GetSkillLevel = function(skill)
        if not self.PlayerData.skills[skill] then return 0 end
        return self.PlayerData.skills[skill].level
    end
    
    -- ═══ REPUTATION SYSTEM ═══
    self.Functions.AddReputation = function(faction, amount)
        if not self.PlayerData.reputation[faction] then return false end
        
        local factionData = Config.Reputation.Factions[faction]
        self.PlayerData.reputation[faction] = VCore.Shared.Math.Clamp(
            self.PlayerData.reputation[faction] + amount,
            factionData.min,
            factionData.max
        )
        
        self.Functions.UpdatePlayerData()
        return true
    end
    
    self.Functions.GetReputation = function(faction)
        return self.PlayerData.reputation[faction] or 0
    end
    
    -- ═══ STATUS MANAGEMENT ═══
    self.Functions.SetStatus = function(status, value)
        if not self.PlayerData.status[status] then return false end
        
        self.PlayerData.status[status] = VCore.Shared.Math.Clamp(value, 0, 100)
        self.Functions.UpdatePlayerData()
        return true
    end
    
    self.Functions.GetStatus = function(status)
        return self.PlayerData.status[status] or 0
    end
    
    -- ═══ INVENTORY MANAGEMENT (Placeholder) ═══
    self.Functions.AddItem = function(item, amount, slot, metadata)
        -- Integration with your inventory system
        return true
    end
    
    self.Functions.RemoveItem = function(item, amount, slot)
        -- Integration with your inventory system
        return true
    end
    
    self.Functions.GetItem = function(item)
        -- Integration with your inventory system
        return nil
    end
    
    self.Functions.GetItemBySlot = function(slot)
        -- Integration with your inventory system
        return nil
    end
    
    self.Functions.GetWeight = function()
        return 0 -- Calculate from inventory
    end
    
    self.Functions.CanCarryItem = function(item, amount)
        return true -- Check weight
    end
    
    -- ═══ SAVE/LOAD ═══
    self.Functions.Save = function()
        MySQL.update('UPDATE players SET currencies = ?, identity = ?, profession = ?, organization = ?, skills = ?, reputation = ?, status = ?, position = ?, metadata = ?, playtime = ? WHERE citizenid = ?', {
            json.encode(self.PlayerData.currencies),
            json.encode({
                firstName = self.PlayerData.firstName,
                lastName = self.PlayerData.lastName,
                dob = self.PlayerData.dob,
                sex = self.PlayerData.sex,
                nationality = self.PlayerData.nationality,
                height = self.PlayerData.height,
                phone = self.PlayerData.phone,
            }),
            json.encode(self.PlayerData.profession),
            json.encode(self.PlayerData.organization),
            json.encode(self.PlayerData.skills),
            json.encode(self.PlayerData.reputation),
            json.encode(self.PlayerData.status),
            json.encode(self.PlayerData.position),
            json.encode({
                bloodType = self.PlayerData.bloodType,
                fingerprint = self.PlayerData.fingerprint,
                walletId = self.PlayerData.walletId,
                callsign = self.PlayerData.callsign,
                licenses = self.PlayerData.licenses,
            }),
            self.PlayerData.playTime,
            self.PlayerData.citizenid
        })
        
        self.PlayerData.lastSave = os.time()
        VCore.Debug('Player saved:', self.PlayerData.firstName, self.PlayerData.lastName)
    end
    
    self.Functions.Logout = function()
        self.Functions.Save()
        VCore.Players[src] = nil
        VCore.PlayerCount = VCore.PlayerCount - 1
    end
    
    -- Add player to active players
    VCore.Players[src] = self
    VCore.PlayerCount = VCore.PlayerCount + 1
    
    return self
end

-- ════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ════════════════════════════════════════════════════════

VCore.Functions.GetPlayer = function(source)
    if type(source) == 'number' then
        return VCore.Players[source]
    else
        return VCore.Players[VCore.Functions.GetSource(source)]
    end
end

VCore.Functions.GetPlayerByCitizenId = function(citizenid)
    for src, player in pairs(VCore.Players) do
        if player.PlayerData.citizenid == citizenid then
            return player
        end
    end
    return nil
end

VCore.Functions.GetPlayers = function()
    local sources = {}
    for k in pairs(VCore.Players) do
        sources[#sources + 1] = k
    end
    return sources
end

VCore.Functions.GetSource = function(identifier)
    for src, player in pairs(VCore.Players) do
        if player.PlayerData.identifier == identifier or
           player.PlayerData.citizenid == identifier or
           player.PlayerData.steam == identifier or
           player.PlayerData.discord == identifier then
            return src
        end
    end
    return 0
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

print('^2[vCore]^7 Player System Loaded')