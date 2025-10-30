-- Admin Commands
lib.addCommand('setjob', {
    help = 'Set player job',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'job', type = 'string', help = 'Job name'},
        {name = 'grade', type = 'number', help = 'Job grade', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = VCore.Functions.GetPlayer(args.id)
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    local grade = args.grade or 0
    
    if Player.Functions.SetJob(args.job, grade) then
        VCore.Functions.Notify(source, 'Job set successfully', 'success')
        VCore.Functions.Notify(args.id, 'Your job has been set to ' .. args.job, 'success')
    else
        VCore.Functions.Notify(source, 'Invalid job', 'error')
    end
end)

lib.addCommand('setgang', {
    help = 'Set player gang',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'gang', type = 'string', help = 'Gang name'},
        {name = 'grade', type = 'number', help = 'Gang grade', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = VCore.Functions.GetPlayer(args.id)
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    local grade = args.grade or 0
    
    if Player.Functions.SetGang(args.gang, grade) then
        VCore.Functions.Notify(source, 'Gang set successfully', 'success')
        VCore.Functions.Notify(args.id, 'Your gang has been set to ' .. args.gang, 'success')
    else
        VCore.Functions.Notify(source, 'Invalid gang', 'error')
    end
end)

lib.addCommand('addmoney', {
    help = 'Add money to player',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'type', type = 'string', help = 'Money type (cash/bank/crypto)'},
        {name = 'amount', type = 'number', help = 'Amount'}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = VCore.Functions.GetPlayer(args.id)
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    if Player.Functions.AddMoney(args.type, args.amount, 'Admin gave money') then
        VCore.Functions.Notify(source, 'Money added successfully', 'success')
        VCore.Functions.Notify(args.id, 'You received $' .. args.amount .. ' ' .. args.type, 'success')
    else
        VCore.Functions.Notify(source, 'Failed to add money', 'error')
    end
end)

lib.addCommand('removemoney', {
    help = 'Remove money from player',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'type', type = 'string', help = 'Money type (cash/bank/crypto)'},
        {name = 'amount', type = 'number', help = 'Amount'}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = VCore.Functions.GetPlayer(args.id)
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    if Player.Functions.RemoveMoney(args.type, args.amount, 'Admin removed money') then
        VCore.Functions.Notify(source, 'Money removed successfully', 'success')
        VCore.Functions.Notify(args.id, '$' .. args.amount .. ' ' .. args.type .. ' was removed', 'error')
    else
        VCore.Functions.Notify(source, 'Failed to remove money', 'error')
    end
end)

lib.addCommand('setmoney', {
    help = 'Set player money',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'type', type = 'string', help = 'Money type (cash/bank/crypto)'},
        {name = 'amount', type = 'number', help = 'Amount'}
    },
    restricted = 'group.admin'
}, function(source, args)
    local Player = VCore.Functions.GetPlayer(args.id)
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    if Player.Functions.SetMoney(args.type, args.amount, 'Admin set money') then
        VCore.Functions.Notify(source, 'Money set successfully', 'success')
        VCore.Functions.Notify(args.id, 'Your ' .. args.type .. ' was set to $' .. args.amount, 'inform')
    else
        VCore.Functions.Notify(source, 'Failed to set money', 'error')
    end
end)

lib.addCommand('kick', {
    help = 'Kick a player',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID'},
        {name = 'reason', type = 'string', help = 'Kick reason', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local reason = args.reason or 'Kicked by administrator'
    VCore.Functions.Kick(args.id, reason, reason)
    VCore.Functions.Notify(source, 'Player kicked', 'success')
end)

lib.addCommand('save', {
    help = 'Save player data',
    params = {
        {name = 'id', type = 'playerId', help = 'Player ID', optional = true}
    },
    restricted = 'group.admin'
}, function(source, args)
    local playerId = args.id or source
    local Player = VCore.Functions.GetPlayer(playerId)
    
    if not Player then
        VCore.Functions.Notify(source, 'Player not found', 'error')
        return
    end
    
    Player.Functions.Save()
    VCore.Functions.Notify(source, 'Player data saved', 'success')
end)

-- Player Commands
lib.addCommand('logout', {
    help = 'Logout and return to character selection'
}, function(source)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return end
    
    Player.Functions.Save()
    Player.Functions.Logout()
    
    TriggerClientEvent('vCore:Client:OnPlayerUnload', source)
    VCore.Functions.Notify(source, 'Logged out successfully', 'success')
end)

lib.addCommand('coords', {
    help = 'Get your current coordinates'
}, function(source)
    local ped = GetPlayerPed(source)
    local coords = VCore.Functions.GetCoords(ped)
    
    print(string.format('Coordinates: vector4(%.2f, %.2f, %.2f, %.2f)', coords.x, coords.y, coords.z, coords.w))
    VCore.Functions.Notify(source, 'Coordinates printed to server console', 'success')
end)

lib.addCommand('toggleduty', {
    help = 'Toggle job duty status'
}, function(source)
    local Player = VCore.Functions.GetPlayer(source)
    if not Player then return end
    
    if Player.PlayerData.job.name == 'unemployed' then
        VCore.Functions.Notify(source, 'You cannot go on duty as unemployed', 'error')
        return
    end
    
    Player.Functions.SetJobDuty()
    local dutyStatus = Player.PlayerData.job.onduty and 'on' or 'off'
    VCore.Functions.Notify(source, 'You are now ' .. dutyStatus .. ' duty', 'success')
end)

-- Utility Commands
lib.addCommand('car', {
    help = 'Spawn a vehicle',
    params = {
        {name = 'model', type = 'string', help = 'Vehicle model'}
    },
    restricted = 'group.admin'
}, function(source, args)
    TriggerClientEvent('vCore:Command:SpawnVehicle', source, args.model)
end)

lib.addCommand('dv', {
    help = 'Delete nearby vehicle',
    restricted = 'group.admin'
}, function(source)
    TriggerClientEvent('vCore:Command:DeleteVehicle', source)
end)

print('^2[vCore]^7 Commands Module Loaded')