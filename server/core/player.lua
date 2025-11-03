-- ╔════════════════════════════════════════════════════════╗
-- ║  vCore Player System - Enterprise Edition             ║
-- ║  Features: Session Management, State Machine, Events  ║
-- ╚════════════════════════════════════════════════════════╝

VCore.PlayerClass = {}
VCore.PlayerClass.__index = VCore.PlayerClass
VCore.ActivePlayers = {}
VCore.PlayerSessions = {}
VCore.PlayerStates = {}

-- ════════════════════════════════════════════════════════
-- PLAYER STATE MACHINE
-- ════════════════════════════════════════════════════════

VCore.PlayerStates = {
    LOADING = 'loading',
    ACTIVE = 'active',
    IDLE = 'idle',
    AFK = 'afk',
    DEAD = 'dead',
    LAST_STAND = 'last_stand',
    SPECTATING = 'spectating',
    DISCONNECTING = 'disconnecting'
}

-- ════════════════════════════════════════════════════════
-- PLAYER CLASS DEFINITION
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:New(source, citizenid)
    local self = setmetatable({}, VCore.PlayerClass)
    
    -- Core Properties
    self.source = source
    self.citizenid = citizenid or VCore.Shared.GenerateId.CitizenId()
    self.state = VCore.PlayerStates.LOADING
    self.lastActivity = os.time()
    self.sessionStart = os.time()
    
    -- Player Data Structure
    self.data = {
        -- Identifiers
        citizenid = self.citizenid,
        identifier = VCore.Functions.GetIdentifier(source, 'license'),
        steam = VCore.Functions.GetIdentifier(source, 'steam'),
        discord = VCore.Functions.GetIdentifier(source, 'discord'),
        license = VCore.Functions.GetIdentifier(source, 'license'),
        ip = GetPlayerEndpoint(source),
        
        -- Identity
        identity = {
            firstName = '',
            lastName = '',
            fullName = '',
            dob = '',
            sex = 'm',
            nationality = 'USA',
            height = 180,
            bloodType = VCore.Shared.BloodTypes[math.random(#VCore.Shared.BloodTypes)],
        },
        
        -- Contact Info
        contact = {
            phone = VCore.Shared.GenerateId.PhoneNumber(),
            email = '',
        },
        
        -- Financial System
        wallet = {
            cash = Config.Wallet.StartingMoney.cash,
            bank = Config.Wallet.StartingMoney.bank,
            crypto = Config.Wallet.StartingMoney.crypto,
            gold = Config.Wallet.StartingMoney.gold,
            chips = Config.Wallet.StartingMoney.chips,
        },
        bankAccount = VCore.Shared.GenerateId.BankAccount(),
        
        -- Profession System
        profession = {
            primary = nil,
            secondary = {},
            history = {}
        },
        
        -- Organization System
        organization = {
            current = nil,
            memberships = {},
            history = {}
        },
        
        -- Skill & Progression
        skills = {},
        achievements = {},
        statistics = {
            playtime = 0,
            distance = 0,
            deaths = 0,
            kills = 0,
            arrests = 0
        },
        
        -- Reputation System
        reputation = {},
        
        -- Status Effects
        status = {
            hunger = 100,
            thirst = 100,
            stress = 0,
            energy = 100,
            hygiene = 100,
            drug = 0,
            alcohol = 0
        },
        
        -- Player State
        state = {
            isDead = false,
            inLastStand = false,
            isHandcuffed = false,
            isParachuting = false,
            isInVehicle = false,
            isSitting = false,
            armor = 0,
            health = 200
        },
        
        -- Location
        position = Config.Spawn.DefaultCoords,
        bucket = 0,
        
        -- Metadata
        metadata = {
            fingerprint = VCore.Shared.GenerateId.Fingerprint(),
            walletId = VCore.Shared.GenerateId.WalletId(),
            callsign = 'NONE',
            phoneData = {
                serialNumber = VCore.Shared.GenerateId.SerialNumber(),
                apps = {}
            }
        },
        
        -- Inventory
        inventory = {},
        maxWeight = 30000,
        
        -- Licenses
        licenses = {},
        
        -- Settings
        settings = {
            voice = {
                range = 'normal',
                muted = false
            },
            hud = {
                visible = true,
                minimap = true
            },
            notifications = true
        },
        
        -- Session
        session = {
            lastLogin = os.time(),
            lastSave = os.time(),
            lastActivity = os.time(),
            playTime = 0,
            loginCount = 0,
            ipHistory = {}
        }
    }
    
    -- Initialize skills
    self:InitializeSkills()
    
    -- Initialize reputation
    self:InitializeReputation()
    
    -- Register player
    VCore.ActivePlayers[source] = self
    
    -- Trigger creation event
    TriggerEvent('vCore:Server:PlayerCreated', source, self)
    
    return self
end

-- ════════════════════════════════════════════════════════
-- INITIALIZATION METHODS
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:InitializeSkills()
    for skill, skillData in pairs(Config.Skills.Types) do
        self.data.skills[skill] = {
            level = 0,
            xp = 0,
            maxXp = 1000,
            multiplier = 1.0
        }
    end
end

function VCore.PlayerClass:InitializeReputation()
    for faction, factionData in pairs(Config.Reputation.Factions) do
        self.data.reputation[faction] = {
            value = 0,
            min = factionData.min,
            max = factionData.max,
            rank = 'Neutral'
        }
    end
end

-- ════════════════════════════════════════════════════════
-- STATE MANAGEMENT
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:SetState(newState)
    local oldState = self.state
    self.state = newState
    
    -- Trigger state change event
    TriggerEvent('vCore:Server:PlayerStateChanged', self.source, oldState, newState)
    TriggerClientEvent('vCore:Client:StateChanged', self.source, newState)
    
    VCore.Debug('Player ' .. self.citizenid .. ' state: ' .. oldState .. ' -> ' .. newState)
end

function VCore.PlayerClass:IsState(state)
    return self.state == state
end

function VCore.PlayerClass:UpdateActivity()
    self.lastActivity = os.time()
    self.data.session.lastActivity = os.time()
    
    if self.state == VCore.PlayerStates.AFK then
        self:SetState(VCore.PlayerStates.ACTIVE)
    end
end

-- ════════════════════════════════════════════════════════
-- CURRENCY MANAGEMENT (Advanced)
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:AddCurrency(currency, amount, reason, silent)
    reason = reason or 'unknown'
    amount = tonumber(amount)
    
    if amount <= 0 then
        VCore.Error('Invalid currency amount: ' .. amount)
        return false
    end
    
    if not self.data.wallet[currency] then
        VCore.Error('Invalid currency type: ' .. currency)
        return false
    end
    
    -- Currency limits
    local currencyConfig = Config.Wallet.Currencies[currency]
    if currency == 'cash' and Config.Wallet.MaxCash then
        if (self.data.wallet.cash + amount) > Config.Wallet.MaxCash then
            if not silent then
                self:Notify('Cannot carry more than $' .. Config.Wallet.MaxCash, 'error')
            end
            return false
        end
    end
    
    -- Apply currency
    local oldAmount = self.data.wallet[currency]
    self.data.wallet[currency] = oldAmount + amount
    
    -- Log transaction
    self:LogTransaction('add', currency, amount, reason, oldAmount, self.data.wallet[currency])
    
    -- Update client
    self:UpdateWallet()
    
    -- Notification
    if not silent and amount >= 100 then
        self:Notify('Received ' .. currencyConfig.prefix .. VCore.Shared.Math.FormatNumber(amount), 'success')
    end
    
    -- Trigger event
    TriggerEvent('vCore:Server:CurrencyChanged', self.source, currency, 'add', amount, reason)
    
    return true
end

function VCore.PlayerClass:RemoveCurrency(currency, amount, reason, silent)
    reason = reason or 'unknown'
    amount = tonumber(amount)
    
    if amount <= 0 then return false end
    if not self.data.wallet[currency] then return false end
    
    -- Check if player has enough
    if self.data.wallet[currency] < amount then
        if not silent then
            self:Notify('Insufficient funds', 'error')
        end
        return false
    end
    
    -- Remove currency
    local oldAmount = self.data.wallet[currency]
    self.data.wallet[currency] = oldAmount - amount
    
    -- Log transaction
    self:LogTransaction('remove', currency, amount, reason, oldAmount, self.data.wallet[currency])
    
    -- Update client
    self:UpdateWallet()
    
    -- Trigger event
    TriggerEvent('vCore:Server:CurrencyChanged', self.source, currency, 'remove', amount, reason)
    
    return true
end

function VCore.PlayerClass:SetCurrency(currency, amount, reason)
    reason = reason or 'admin_set'
    amount = tonumber(amount)
    
    if amount < 0 then return false end
    if not self.data.wallet[currency] then return false end
    
    local oldAmount = self.data.wallet[currency]
    self.data.wallet[currency] = amount
    
    self:LogTransaction('set', currency, amount, reason, oldAmount, amount)
    self:UpdateWallet()
    
    TriggerEvent('vCore:Server:CurrencyChanged', self.source, currency, 'set', amount, reason)
    
    return true
end

function VCore.PlayerClass:GetCurrency(currency)
    return self.data.wallet[currency] or 0
end

function VCore.PlayerClass:HasCurrency(currency, amount)
    return self:GetCurrency(currency) >= amount
end

function VCore.PlayerClass:TransferCurrency(targetPlayer, currency, amount, reason)
    if not self:HasCurrency(currency, amount) then
        self:Notify('Insufficient funds for transfer', 'error')
        return false
    end
    
    local currencyConfig = Config.Wallet.Currencies[currency]
    if not currencyConfig.canTrade then
        self:Notify('This currency cannot be transferred', 'error')
        return false
    end
    
    -- Apply tax if configured
    local tax = 0
    if Config.Wallet.BankTax and currency == 'bank' then
        tax = math.floor(amount * Config.Wallet.BankTax)
        amount = amount - tax
    end
    
    if self:RemoveCurrency(currency, amount + tax, reason or 'transfer', true) then
        if targetPlayer:AddCurrency(currency, amount, reason or 'received_transfer', true) then
            self:Notify('Transferred ' .. currencyConfig.prefix .. amount, 'success')
            targetPlayer:Notify('Received ' .. currencyConfig.prefix .. amount, 'success')
            
            TriggerEvent('vCore:Server:CurrencyTransferred', self.source, targetPlayer.source, currency, amount, tax)
            return true
        else
            -- Refund if target couldn't receive
            self:AddCurrency(currency, amount + tax, 'transfer_refund', true)
        end
    end
    
    return false
end

function VCore.PlayerClass:UpdateWallet()
    TriggerClientEvent('vCore:Client:UpdateWallet', self.source, self.data.wallet)
end

function VCore.PlayerClass:LogTransaction(type, currency, amount, reason, oldBalance, newBalance)
    -- Log to database
    MySQL.insert('INSERT INTO currency_logs (citizenid, type, currency, amount, reason, old_balance, new_balance, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        self.citizenid,
        type,
        currency,
        amount,
        reason,
        oldBalance,
        newBalance,
        os.time()
    })
end

-- ════════════════════════════════════════════════════════
-- PROFESSION MANAGEMENT (Advanced)
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:SetProfession(professionName, level, isPrimary)
    if not Config.Professions.Types[professionName] then
        VCore.Error('Invalid profession: ' .. professionName)
        return false
    end
    
    local professionData = Config.Professions.Types[professionName]
    level = tonumber(level) or 0
    
    local profession = {
        name = professionName,
        label = professionData.label,
        level = level,
        xp = 0,
        maxXp = level * 1000,
        rank = self:GetProfessionRank(level),
        salary = professionData.salary,
        onDuty = false,
        isBoss = false,
        skills = professionData.skills or {},
        joinedAt = os.time()
    }
    
    if isPrimary or not self.data.profession.primary then
        -- Save old profession to history
        if self.data.profession.primary then
            table.insert(self.data.profession.history, self.data.profession.primary)
        end
        
        self.data.profession.primary = profession
        
        -- Trigger events
        TriggerEvent('vCore:Server:ProfessionChanged', self.source, profession)
        TriggerClientEvent('vCore:Client:OnProfessionUpdate', self.source, profession)
    else
        -- Add as secondary profession
        if Config.Professions.EnableMultipleProfessions then
            if #self.data.profession.secondary >= Config.Professions.MaxActiveProfessions then
                self:Notify('Maximum secondary professions reached', 'error')
                return false
            end
            
            table.insert(self.data.profession.secondary, profession)
        else
            self:Notify('Multiple professions not enabled', 'error')
            return false
        end
    end
    
    self:UpdatePlayerData()
    return true
end

function VCore.PlayerClass:GetProfessionRank(level)
    if level >= 80 then return 'Master'
    elseif level >= 60 then return 'Expert'
    elseif level >= 40 then return 'Advanced'
    elseif level >= 20 then return 'Intermediate'
    elseif level >= 10 then return 'Beginner'
    else return 'Novice' end
end

function VCore.PlayerClass:AddProfessionXP(amount, professionName)
    local profession = professionName and 
        self:GetSecondaryProfession(professionName) or 
        self.data.profession.primary
    
    if not profession then return false end
    
    profession.xp = profession.xp + amount
    
    -- Level up check
    while profession.xp >= profession.maxXp and profession.level < Config.Professions.MaxLevel do
        profession.level = profession.level + 1
        profession.xp = profession.xp - profession.maxXp
        profession.maxXp = profession.level * 1000
        profession.rank = self:GetProfessionRank(profession.level)
        
        self:Notify('Profession Level Up! ' .. profession.label .. ' is now level ' .. profession.level, 'success')
        TriggerEvent('vCore:Server:ProfessionLevelUp', self.source, profession.name, profession.level)
    end
    
    self:UpdatePlayerData()
    return true
end

function VCore.PlayerClass:GetSecondaryProfession(professionName)
    for _, prof in ipairs(self.data.profession.secondary) do
        if prof.name == professionName then
            return prof
        end
    end
    return nil
end

function VCore.PlayerClass:ToggleDuty()
    if not self.data.profession.primary then return false end
    
    self.data.profession.primary.onDuty = not self.data.profession.primary.onDuty
    
    TriggerClientEvent('vCore:Client:DutyUpdate', self.source, self.data.profession.primary.onDuty)
    TriggerEvent('vCore:Server:DutyChanged', self.source, self.data.profession.primary.onDuty)
    
    self:UpdatePlayerData()
    return self.data.profession.primary.onDuty
end

-- ════════════════════════════════════════════════════════
-- SKILL SYSTEM (Advanced with Multipliers)
-- ════════════════════════════════════════════════════════

function VCore.PlayerClass:AddSkillXP(skill, xp, silent)
    if not self.data.skills[skill] then return false end
    
    local skillData = self.data.skills[skill]
    xp = xp * skillData.multiplier * (Config.Skills.ExperienceMultiplier or 1.0)
    
    skillData.xp = skillData.xp + xp
    
    -- Level up
    while skillData.xp >= skillData.maxXp and skillData.level < Config.Skills.MaxLevel do
        skillData.level = skillData.level + 1
        skillData.xp = skillData.xp - skillData.maxXp
        skillData.maxXp = skillData.level * 1000
        
        if not silent then
            self:Notify('Skill Level Up! ' .. Config.Skills.Types[skill].label .. ' is now level ' .. skillData.level, 'success')
        end
        
        TriggerEvent('vCore:Server:SkillLevelUp', self.source, skill, skillData.level)
    end
    
    self:UpdatePlayerData()
    return true
end

function VCore.PlayerClass:GetSkillLevel(skill)
    return self.data.skills[skill] and self.data.skills[skill].level or 0
end

function VCore.PlayerClass:SetSkillMultiplier(skill, multiplier)
    if not self.data.skills[skill] then return false end
    self.data.skills[skill].multiplier = multiplier
    return true
end

-- Continued in next artifact...