-- BibiModz Script https://discord.gg/dr9UuDgT8N

Config = {}

-- Modèles
Config.TaxiModel = `taxi`
Config.DriverModel = `a_m_m_business_01`
Config.NpcModel = `a_m_m_business_01`

-- Coordonnées du NPC Taxi
Config.NpcPosition = vector3(-1036.52734375, -2731.7763671875, 20.169290542603)
Config.NpcHeading = 147.1365814209

-- Distance
Config.SpawnDistance = 50.0
Config.TaxiArrivalDistance = 10.0
Config.DestinationArrivalDistance = 10.0

-- Conduite
Config.TaxiSpeed = 20.0
Config.TaxiDrivingStyle = 786603

-- Notifications
Config.TaxiNotifyTitle = "Taxi"
Config.TaxiNotifyMessages = {
    inRoute = "Votre taxi est en route.",
    waiting = "Votre taxi vous attend. Montez à l'arrière.",
    arrived = "Vous êtes arrivé à destination. Sortez du véhicule.",
    canceled = "Votre course a été annulée.",
    alreadyInProgress = "Un taxi est déjà en route.",
    noDestination = "Aucune destination trouvée sur la carte.",
}

-- ox_target
Config.OxTargetIcon = "fa-solid fa-taxi"
Config.OxTargetLabel = "Parler au chauffeur de taxi"

-- Menus
Config.Menu = {
    title = "Menu Taxi",
    options = {
        {
            title = "Appeler un taxi",
            description = "Demandez à un taxi de venir vous chercher.",
            event = "callTaxi"
        },
        {
            title = "Annuler la course",
            description = "Annulez votre course en taxi actuelle.",
            event = "cancelTaxi"
        }
    }
}

Config.PricePerMeter = 0.5 -- Prix par mètre parcouru | 0.0 aucune facture 


-- BibiModz Script https://discord.gg/dr9UuDgT8N
