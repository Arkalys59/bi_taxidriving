ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('esx_billing:sendBill')
AddEventHandler('esx_billing:sendBill', function(playerId, society, label, amount)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    if xPlayer then
        MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, amount, label, society) VALUES (@identifier, @sender, @target_type, @amount, @label, @society)', {
            ['@identifier'] = xPlayer.identifier,
            ['@sender'] = society,
            ['@target_type'] = 'player',
            ['@amount'] = amount,
            ['@label'] = label,
            ['@society'] = society
        }, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerClientEvent('esx:showNotification', playerId, 'Vous avez reçu une facture de ' .. amount .. '$ pour ' .. label)
            else
                TriggerClientEvent('esx:showNotification', playerId, 'Erreur lors de la création de la facture.')
            end
        end)
    end
end)
