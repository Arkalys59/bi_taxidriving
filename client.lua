local startPoint = nil
local totalCost = 0
local taxiInProgress = false
local taxiArrived = false
local taxiEntity, driverEntity, taxiBlip = nil

function loadModel(model)
    RequestModel(model)
    local retries = 0
    while not HasModelLoaded(model) and retries < 20 do
        retries = retries + 1
        Wait(100)
    end
    if not HasModelLoaded(model) then
        print("Erreur : Le modèle " .. tostring(model) .. " n'a pas pu être chargé.")
        return false
    end
    return true
end

function spawnTaxiNPC()
    local npcPos = Config.NpcPosition
    local npcHeading = Config.NpcHeading

    if not loadModel(Config.NpcModel) then
        print("Erreur : Impossible de charger le modèle du NPC.")
        return
    end

    npcEntity = CreatePed(4, Config.NpcModel, npcPos.x, npcPos.y, npcPos.z - 1.0, npcHeading, false, true)
    SetEntityAsMissionEntity(npcEntity, true, true)
    SetBlockingOfNonTemporaryEvents(npcEntity, true)
    FreezeEntityPosition(npcEntity, true)

    exports.ox_target:addLocalEntity(npcEntity, {
        {
            name = "menu_taxi",
            event = "openTaxiMenu",
            icon = Config.OxTargetIcon,
            label = Config.OxTargetLabel
        }
    })
end

function callTaxi()
    if taxiInProgress then
        lib.notify({
            title = Config.TaxiNotifyTitle,
            description = Config.TaxiNotifyMessages.alreadyInProgress,
            type = "error"
        })
        return
    end

    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    if not loadModel(Config.TaxiModel) or not loadModel(Config.DriverModel) then
        print("Erreur : Impossible de charger le modèle du taxi ou du chauffeur.")
        return
    end

    local spawnPos = GetOffsetFromEntityInWorldCoords(playerPed, Config.SpawnDistance, 0.0, 0.0)

    taxiEntity = CreateVehicle(Config.TaxiModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
    SetVehicleOnGroundProperly(taxiEntity)
    SetEntityAsMissionEntity(taxiEntity, true, true)

    driverEntity = CreatePedInsideVehicle(taxiEntity, 26, Config.DriverModel, -1, true, false)
    SetEntityAsMissionEntity(driverEntity, true, true)

    SetEntityInvincible(driverEntity, true)
    SetPedFleeAttributes(driverEntity, 0, false)
    SetBlockingOfNonTemporaryEvents(driverEntity, true)
    TaskSetBlockingOfNonTemporaryEvents(driverEntity, true)

    taxiBlip = AddBlipForEntity(taxiEntity)
    SetBlipSprite(taxiBlip, 198)
    SetBlipColour(taxiBlip, 5)
    SetBlipFlashes(taxiBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Taxi")
    EndTextCommandSetBlipName(taxiBlip)

    taxiInProgress = true

    TaskVehicleDriveToCoord(driverEntity, taxiEntity, playerPos.x, playerPos.y, playerPos.z, Config.TaxiSpeed, 0, Config.TaxiModel, Config.TaxiDrivingStyle, 1.0, true)

    Citizen.CreateThread(function()
        while true do
            Wait(500)

            local playerPos = GetEntityCoords(playerPed)
            local taxiPos = GetEntityCoords(taxiEntity)
            local distanceToPlayer = #(playerPos - taxiPos)

            
            if distanceToPlayer < 10.0 then
                
                local seatIndex = 1 
                if not IsVehicleSeatFree(taxiEntity, 1) then
                    seatIndex = 2 
                end
                TaskEnterVehicle(playerPed, taxiEntity, -1, seatIndex, 1.0, 1, 0)

                
                while not IsPedInVehicle(playerPed, taxiEntity, false) do
                    Wait(500)
                end

                startPoint = GetEntityCoords(taxiEntity) 

                local blip = GetFirstBlipInfoId(8)
                if DoesBlipExist(blip) then
                    local blipPos = GetBlipInfoIdCoord(blip)

                    TaskVehicleDriveToCoord(driverEntity, taxiEntity, blipPos.x, blipPos.y, blipPos.z, Config.TaxiSpeed, 0, Config.TaxiModel, Config.TaxiDrivingStyle, 1.0, false)

                    Citizen.CreateThread(function()
                        while true do
                            Wait(1000)

                            local taxiPos = GetEntityCoords(taxiEntity)
                            local distanceToDestination = #(blipPos - taxiPos)

                            if distanceToDestination < Config.DestinationArrivalDistance then
                                TaskVehicleTempAction(driverEntity, taxiEntity, 1, -1)

                                lib.notify({
                                    title = Config.TaxiNotifyTitle,
                                    description = Config.TaxiNotifyMessages.arrived,
                                    type = "success"
                                })
                                while IsPedInVehicle(playerPed, taxiEntity, false) do
                                    Wait(500)
                                end

                                local endPoint = GetEntityCoords(taxiEntity)
                                local distanceTraveled = #(startPoint - endPoint)
                                totalCost = math.floor(distanceTraveled * Config.PricePerMeter)

                                if totalCost > 0 then
                                    processPayment(totalCost)
                                end

                                TaskVehiclePark(driverEntity, taxiEntity, taxiPos.x, taxiPos.y, taxiPos.z, GetEntityHeading(taxiEntity), 0, 20.0, false)
                                TaskLeaveVehicle(driverEntity, taxiEntity, 0)
                                SetVehicleEngineOn(taxiEntity, false, true, false)
                                FreezeEntityPosition(driverEntity, true)

                                DeleteEntity(taxiEntity)
                                DeleteEntity(driverEntity)
                                if DoesBlipExist(taxiBlip) then
                                    RemoveBlip(taxiBlip)
                                end
                                taxiInProgress = false
                                taxiArrived = true
                                break
                            end
                        end
                    end)
                else
                    print("Aucun point GPS trouvé sur la carte.")
                    DeleteEntity(taxiEntity)
                    DeleteEntity(driverEntity)
                    if DoesBlipExist(taxiBlip) then
                        RemoveBlip(taxiBlip)
                    end
                    taxiInProgress = false
                end
                break
            end
        end
    end)
end

function processPayment(cost)
    local playerId = GetPlayerServerId(PlayerId())

    if Config.PricePerMeter == 0.0 or cost == 0 then
        lib.notify({
            title = Config.TaxiNotifyTitle,
            description = "La course était gratuite.",
            type = "inform"
        })
        return
    end

    TriggerServerEvent('esx_billing:sendBill', playerId, 'society_taxi', 'Taxi Service', cost)

    lib.notify({
        title = Config.TaxiNotifyTitle,
        description = "Vous avez reçu une facture de $" .. cost .. " pour la course.",
        type = "success"
    })
end

function cancelTaxi()
    if taxiInProgress then
        DeleteEntity(taxiEntity)
        DeleteEntity(driverEntity)
        if DoesBlipExist(taxiBlip) then
            RemoveBlip(taxiBlip)
        end
        taxiInProgress = false
        lib.notify({
            title = Config.TaxiNotifyTitle,
            description = Config.TaxiNotifyMessages.canceled,
            type = "error"
        })
    else
        lib.notify({
            title = Config.TaxiNotifyTitle,
            description = Config.TaxiNotifyMessages.noDestination,
            type = "error"
        })
    end
end

function openTaxiMenu()
    lib.registerContext({
        id = 'taxi_menu',
        title = Config.Menu.title,
        options = Config.Menu.options
    })
    lib.showContext('taxi_menu')
end

RegisterNetEvent('openTaxiMenu')
AddEventHandler('openTaxiMenu', function()
    openTaxiMenu()
end)

RegisterNetEvent('callTaxi')
AddEventHandler('callTaxi', function()
    callTaxi()
end)

RegisterNetEvent('cancelTaxi')
AddEventHandler('cancelTaxi', function()
    cancelTaxi()
end)

RegisterCommand("taxi", function()
    openTaxiMenu()
end, false)

CreateThread(function()
    spawnTaxiNPC()
end)
