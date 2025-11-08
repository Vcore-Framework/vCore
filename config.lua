Config = Config or {}
Config.Debug = false -- Set to true to enable debug messages

-- vCore Unique Features
Config.Framework = {
    Name = 'vCore',
    Version = '2.0.0',
    UseModularSystem = true, -- Unique module-based architecture
    EnableHotReload = true, -- Hot reload modules without restart
    EnableBridge = true, -- Enable multi-framework bridge
    BridgeMode = 'auto', -- auto, qb, esx, ox, none
}

-- Advanced Session System (Unique to vCore)
Config.Session = {
    Enabled = true,
    AutoSave = true,
    SaveInterval = 5, -- Minutes
    UseRedis = false, -- Future: Redis session storage
    SessionTimeout = 30, -- Minutes of inactivity
    CloudSync = false, -- Future: Cloud character sync
}

-- Identity System (Different from other frameworks)
Config.Identity = {
    System = 'integrated', -- integrated, external
    RequireRealAge = false,
    MinAge = 18,
    MaxAge = 90,
    AllowMultipleCharacters = true,
    MaxCharacters = 5,
    CharacterSlots = {
        [0] = {price = 0}, -- Free slot
        [1] = {price = 0}, -- Free slot
        [2] = {price = 50000}, -- Paid slot
        [3] = {price = 100000}, -- Paid slot
        [4] = {price = 250000}, -- Paid slot
    }
}

-- Wallet System (Unique multi-wallet approach)
Config.Wallet = {
    Enabled = true,
    Currencies = {
        ['cash'] = {label = 'Cash', prefix = '$', canDrop = true, canTrade = true},
        ['bank'] = {label = 'Bank', prefix = '$', canDrop = false, canTrade = false},
        ['crypto'] = {label = 'Crypto', prefix = '₿', canDrop = false, canTrade = true},
        ['gold'] = {label = 'Gold', prefix = 'G', canDrop = false, canTrade = true},
        ['chips'] = {label = 'Casino Chips', prefix = 'C', canDrop = false, canTrade = false},
    },
    StartingMoney = {
        cash = 5000,
        bank = 25000,
        crypto = 0,
        gold = 0,
        chips = 0,
    },
    MaxCash = 50000, -- Max cash you can carry
    BankTax = 0.01, -- 1% tax on bank transfers
}

-- Profession System (Not "jobs" - more flexible)
Config.Professions = {
    EnableMultipleProfessions = true, -- Unique: Players can have multiple professions
    MaxActiveProfessions = 2,
    LevelSystem = true, -- Profession leveling system
    MaxLevel = 100,
    
    Types = {
        ['citizen'] = {
            label = 'Citizen',
            description = 'Independent civilian',
            salary = 0,
            skills = {},
            isPrimary = true,
        },
        ['lawenforcement'] = {
            label = 'Law Enforcement',
            description = 'Police and federal agents',
            salary = 150,
            skills = {'combat', 'investigation'},
            isPrimary = true,
            requiresWhitelist = true,
        },
        ['medical'] = {
            label = 'Medical Professional',
            description = 'Doctors and paramedics',
            salary = 125,
            skills = {'medicine', 'surgery'},
            isPrimary = true,
            requiresWhitelist = true,
        },
        ['mechanic'] = {
            label = 'Mechanic',
            description = 'Vehicle repair specialist',
            salary = 100,
            skills = {'repair', 'tuning'},
            isPrimary = false,
        },
        ['fisherman'] = {
            label = 'Fisherman',
            description = 'Commercial fishing',
            salary = 0,
            skills = {'fishing'},
            isPrimary = false,
        },
        ['miner'] = {
            label = 'Miner',
            description = 'Resource extraction',
            salary = 0,
            skills = {'mining'},
            isPrimary = false,
        },
    }
}

-- Organization System (Replaces "gangs" with more flexibility)
Config.Organizations = {
    Enabled = true,
    MaxMembers = 50,
    EnableTerritories = true,
    EnableWarehouses = true,
    EnableBusiness = true,
    
    Types = {
        legal = {
            label = 'Legal Business',
            canOwnProperty = true,
            canHireEmployees = true,
            showOnMap = true,
        },
        illegal = {
            label = 'Criminal Organization',
            canOwnProperty = true,
            canHireEmployees = true,
            showOnMap = false,
        },
        government = {
            label = 'Government Agency',
            canOwnProperty = true,
            canHireEmployees = true,
            showOnMap = true,
        },
    }
}

-- Status System (More detailed than other frameworks)
Config.Status = {
    Enabled = true,
    UpdateInterval = 30000, -- 30 seconds
    
    Effects = {
        hunger = {
            enabled = true,
            decreaseRate = 0.8, -- Per interval
            critical = 10,
            effects = {'stamina_decrease', 'health_decrease'},
        },
        thirst = {
            enabled = true,
            decreaseRate = 1.2,
            critical = 10,
            effects = {'stamina_decrease', 'vision_blur'},
        },
        stress = {
            enabled = true,
            decreaseRate = 0.5,
            critical = 90,
            effects = {'screen_shake', 'hearing_loss'},
        },
        energy = {
            enabled = true,
            decreaseRate = 0.3,
            critical = 10,
            effects = {'movement_slow', 'action_slow'},
        },
        hygiene = {
            enabled = true,
            decreaseRate = 0.1,
            critical = 20,
            effects = {'social_penalty'},
        },
    }
}

-- Skill System (Unique RPG-like progression)
Config.Skills = {
    Enabled = true,
    MaxLevel = 100,
    ExperienceMultiplier = 1.0,
    
    Types = {
        combat = {label = 'Combat', icon = 'gun'},
        driving = {label = 'Driving', icon = 'car'},
        flying = {label = 'Flying', icon = 'plane'},
        fishing = {label = 'Fishing', icon = 'fish'},
        mining = {label = 'Mining', icon = 'pickaxe'},
        medicine = {label = 'Medicine', icon = 'heart'},
        repair = {label = 'Repair', icon = 'wrench'},
        cooking = {label = 'Cooking', icon = 'utensils'},
        farming = {label = 'Farming', icon = 'tractor'},
        lockpicking = {label = 'Lockpicking', icon = 'key'},
        hacking = {label = 'Hacking', icon = 'laptop'},
        trading = {label = 'Trading', icon = 'handshake'},
    }
}

-- Reputation System (Faction reputation)
Config.Reputation = {
    Enabled = true,
    Factions = {
        police = {label = 'Police Department', min = -100, max = 100},
        medical = {label = 'Medical Services', min = -100, max = 100},
        gangs = {label = 'Street Reputation', min = -100, max = 100},
        citizens = {label = 'Citizen Trust', min = -100, max = 100},
        government = {label = 'Government', min = -100, max = 100},
    }
}

-- Spawn System
Config.Spawn = {
    DefaultCoords = vector4(-1035.71, -2731.87, 12.75, 0.0),
    EnableHousing = true,
    EnableHotels = true,
    EnableLastPosition = true,
    SpawnPriority = {'property', 'hotel', 'last_position', 'default'},
}

-- Player Settings
Config.Player = {
    RevealMap = true,
    EnableVoiceChat = true,
    EnableProximityChat = true,
    EnableAFK = true,
    AFKTimeout = 15, -- Minutes
    AFKKick = false,
    DropInventoryOnDeath = true,
    DropMoneyOnDeath = true,
    DropWeaponsOnDeath = true,
    RespawnTime = 300, -- Seconds
}

-- Server Settings
Config.Server = {
    Closed = false,
    ClosedReason = 'Server maintenance in progress',
    Whitelist = false,
    RequireDiscord = false,
    RequireSteam = true,
    MaxPlayers = GetConvarInt('sv_maxclients', 48),
    EnableQueue = false,
    EnablePriority = false,
}

-- Database
Config.Database = {
    Debug = false,
    SlowQueryWarning = 100, -- ms
    EnableQueryLogging = false,
}

-- Bridge Settings
Config.Bridge = {
    Framework = 'vcore', -- vcore, qb, esx, ox
    AutoDetect = true,
    EnableLegacySupport = true,
    MapResourceNames = {
        ['qb-core'] = 'qbcore',
        ['es_extended'] = 'esx',
        ['ox_core'] = 'oxcore',
    }
}