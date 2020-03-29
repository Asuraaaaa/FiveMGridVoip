RegisterServerEvent("ResyncChannel")
AddEventHandler("ResyncChannel", function(channelID)
TriggerClientEvent("C_ResyncChannel", -1, channelID)
end)
