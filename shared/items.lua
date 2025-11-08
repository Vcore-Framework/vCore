VCore.Shared.Items = {
    -- Weapons
    ['weapon_pistol'] = {
        name = 'weapon_pistol',
        label = 'Pistol',
        weight = 1000,
        type = 'weapon',
        ammotype = 'AMMO_PISTOL',
        image = 'weapon_pistol.png',
        unique = true,
        useable = false,
        description = 'A standard pistol'
    },
    
    -- Money Items
    ['black_money'] = {
        name = 'black_money',
        label = 'Dirty Money',
        weight = 0,
        type = 'item',
        image = 'black_money.png',
        unique = false,
        useable = false,
        shouldClose = false,
        description = 'Money that probably doesn\'t belong to you'
    },
    
    -- Basic Items
    ['phone'] = {
        name = 'phone',
        label = 'Phone',
        weight = 500,
        type = 'item',
        image = 'phone.png',
        unique = true,
        useable = true,
        shouldClose = true,
        description = 'A smartphone'
    },
    
    ['id_card'] = {
        name = 'id_card',
        label = 'ID Card',
        weight = 0,
        type = 'item',
        image = 'id_card.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Your identification card'
    },
    
    ['driver_license'] = {
        name = 'driver_license',
        label = 'Driver License',
        weight = 0,
        type = 'item',
        image = 'driver_license.png',
        unique = true,
        useable = true,
        shouldClose = false,
        description = 'Your driver license'
    },
    
    -- Food & Drink
    ['water_bottle'] = {
        name = 'water_bottle',
        label = 'Water Bottle',
        weight = 500,
        type = 'item',
        image = 'water_bottle.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Fresh water'
    },
    
    ['sandwich'] = {
        name = 'sandwich',
        label = 'Sandwich',
        weight = 200,
        type = 'item',
        image = 'sandwich.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'A tasty sandwich'
    },
    
    ['coffee'] = {
        name = 'coffee',
        label = 'Coffee',
        weight = 300,
        type = 'item',
        image = 'coffee.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Hot coffee'
    },
    
    -- Medical Items
    ['bandage'] = {
        name = 'bandage',
        label = 'Bandage',
        weight = 100,
        type = 'item',
        image = 'bandage.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Used for treating wounds'
    },
    
    ['firstaid'] = {
        name = 'firstaid',
        label = 'First Aid Kit',
        weight = 500,
        type = 'item',
        image = 'firstaid.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Medical supplies for emergencies'
    },
    
    ['painkillers'] = {
        name = 'painkillers',
        label = 'Painkillers',
        weight = 100,
        type = 'item',
        image = 'painkillers.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Reduces pain'
    },
    
    -- Tools
    ['lockpick'] = {
        name = 'lockpick',
        label = 'Lockpick',
        weight = 100,
        type = 'item',
        image = 'lockpick.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Used for picking locks'
    },
    
    ['advancedlockpick'] = {
        name = 'advancedlockpick',
        label = 'Advanced Lockpick',
        weight = 200,
        type = 'item',
        image = 'advancedlockpick.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'An advanced lockpick set'
    },
    
    ['repairkit'] = {
        name = 'repairkit',
        label = 'Repair Kit',
        weight = 2500,
        type = 'item',
        image = 'repairkit.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Vehicle repair kit'
    },
    
    ['advancedrepairkit'] = {
        name = 'advancedrepairkit',
        label = 'Advanced Repair Kit',
        weight = 4000,
        type = 'item',
        image = 'advancedrepairkit.png',
        unique = false,
        useable = true,
        shouldClose = true,
        description = 'Professional vehicle repair kit'
    },
    
    -- Vehicle Items
    ['car_keys'] = {
        name = 'car_keys',
        label = 'Car Keys',
        weight = 100,
        type = 'item',
        image = 'car_keys.png',
        unique = true,
        useable = true,
        shouldClose = true,
        description = 'Vehicle keys'
    },
    
    -- Electronics
    ['radio'] = {
        name = 'radio',
        label = 'Radio',
        weight = 500,
        type = 'item',
        image = 'radio.png',
        unique = true,
        useable = true,
        shouldClose = true,
        description = 'Communication device'
    },
    
    ['laptop'] = {
        name = 'laptop',
        label = 'Laptop',
        weight = 2000,
        type = 'item',
        image = 'laptop.png',
        unique = true,
        useable = true,
        shouldClose = true,
        description = 'A portable computer'
    },
    
    -- Misc
    ['backpack'] = {
        name = 'backpack',
        label = 'Backpack',
        weight = 500,
        type = 'item',
        image = 'backpack.png',
        unique = true,
        useable = true,
        shouldClose = true,
        description = 'Increases inventory space'
    }
}

-- Function to get item by name
VCore.Shared.GetItem = function(itemName)
    return VCore.Shared.Items[itemName]
end

-- Function to get all items
VCore.Shared.GetAllItems = function()
    return VCore.Shared.Items
end

print('^2[vCore]^7 Items Module Loaded')