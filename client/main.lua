--[[ ===================================================== ]]--
--[[      QBCore Realistic Parking Script by MaDHouSe      ]]--
--[[ ===================================================== ]]--

local QBCore             = exports['qb-core']:GetCoreObject()
local PlayerData         = {}
local PlayerJob          = {}
local LocalVehicles      = {}
local GlobalVehicles     = {}
local ParkZones          = {}
local UpdateAvailable    = false
local SpawnedVehicles    = false
local isUsingParkCommand = false
local IsDeleting         = false
local OnDuty             = false
local InParking          = false
local IsInParkZone       = false
local CreateMode         = false
local LastUsedPlate      = nil
local ParkOwnerName      = nil
local ParkAction         = 'none'
local extraRadius        = 3
local citizenid          = 0

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    if Config.UseOnJoinRefresh then
        TriggerServerEvent("qb-parking:server:refreshVehicles", 'allparking')
    end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerJob = job
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    OnDuty = duty
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)


local function CreateParkDisPlay(vehicleData, type)
    local info, model, owner, plate = nil
    local viewType = ""
    if type == 'police'  then if Config.DisplayPlayerAndPolice then viewType = Lang:t('info.police_info')..'\n'  end end
    if type == 'citizen' then if Config.DisplayPlayerAndPolice then viewType = Lang:t('info.citizen_info')..'\n' end end
    owner = string.format(Lang:t("info.owner", {owner = vehicleData.citizenname}))..'\n'
    model = viewType .. string.format(Lang:t("info.model", {model = vehicleData.modelname}))..'\n'
    plate = string.format(Lang:t("info.plate", {plate = vehicleData.plate}))..'\n'
    info  = string.format("%s", model..plate..owner)
    return info
end

-- Do Vehicle damage
local function doCarDamage(vehicle, health)
	local engine = health.engine + 0.0
	local body = health.body + 0.0
    if body < 150 then body = 150 end
    if engine < 150 then engine = 150 end
    if body < 900.0 then
		SmashVehicleWindow(vehicle, 0)
		SmashVehicleWindow(vehicle, 1)
		SmashVehicleWindow(vehicle, 2)
		SmashVehicleWindow(vehicle, 3)
		SmashVehicleWindow(vehicle, 4)
		SmashVehicleWindow(vehicle, 5)
		SmashVehicleWindow(vehicle, 6)
		SmashVehicleWindow(vehicle, 7)
	end
	if body < 800.0 then
		SetVehicleDoorBroken(vehicle, 0, true)
		SetVehicleDoorBroken(vehicle, 1, true)
		SetVehicleDoorBroken(vehicle, 2, true)
		SetVehicleDoorBroken(vehicle, 3, true)
		SetVehicleDoorBroken(vehicle, 4, true)
		SetVehicleDoorBroken(vehicle, 5, true)
		SetVehicleDoorBroken(vehicle, 6, true)
	end
	if engine < 700.0 then
		SetVehicleTyreBurst(vehicle, 1, false, 990.0)
		SetVehicleTyreBurst(vehicle, 2, false, 990.0)
		SetVehicleTyreBurst(vehicle, 3, false, 990.0)
		SetVehicleTyreBurst(vehicle, 4, false, 990.0)
	end
	if engine < 500.0 then
		SetVehicleTyreBurst(vehicle, 0, false, 990.0)
		SetVehicleTyreBurst(vehicle, 5, false, 990.0)
		SetVehicleTyreBurst(vehicle, 6, false, 990.0)
		SetVehicleTyreBurst(vehicle, 7, false, 990.0)
	end
    SetVehicleEngineHealth(vehicle, engine)
    SetVehicleBodyHealth(vehicle, body)
end

-- Create parked vehicle blips
local function CreateParkedBlip(label, location)
    local blip = nil
    if Config.UseParkingBlips then
        blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, 545)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.6)
        SetBlipAsShortRange(blip, true)
        SetBlipColour(blip, 25)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

-- Set No Collission between 2 entities
local function NoColission(entity, location)
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(vector3(location.x, location.y, location.z))
    if distance <= 1 then
        SetEntityNoCollisionEntity(entity, vehicle, true)
    end
end

-- Set fuel
local function SetFuel(vehicle, fuel)
	if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
		SetVehicleFuelLevel(vehicle, fuel + 0.0)
		DecorSetFloat(vehicle, "_FUEL_LEVEL", GetVehicleFuelLevel(vehicle))
	end
end

-- trailer offset position
local function trailerOffset(vehicle)
    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    local displaytext  = GetDisplayNameFromVehicleModel(vehicleProps["model"])
    local offset = 0.0
    if Config.Trailers[displaytext] then offset = Config.Trailers[displaytext].offset end
    return offset
end

-- Vehicle Spawn
local function VehicleSpawn(data, warp)
    local tmpvehicle
    QBCore.Functions.LoadModel(data.model)
    QBCore.Functions.SpawnVehicle(data.model, function(veh)
        tmpvehicle = veh
        NoColission(veh, data.vehicle.coords)
        QBCore.Functions.SetVehicleProperties(veh, data.vehicle.props)
        SetVehicleNumberPlateText(veh, data.plate)
        SetEntityAsMissionEntity(veh, true, true)
        SetEntityHeading(veh, data.vehicle.coords.w)
        local offset = trailerOffset(veh)
        SetEntityCoords(veh, data.vehicle.coords.x, data.vehicle.coords.y, data.vehicle.coords.z - offset, false, false, false, true);
        SetVehicleOnGroundProperly(veh)
        SetVehicleDoorsLocked(veh, 2)
        if warp then 
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            SetVehicleEngineOn(veh, true, true, true) 
        end
        FreezeEntityPosition(veh, true)
        SetEntityCanBeDamaged(veh, false)
        SetCanClimbOnEntity(veh, false)
        SetEntityInvincible(veh, false)
        SetVehRadioStation(veh, 'OFF')
        SetVehicleDirtLevel(veh, 0)
        doCarDamage(veh, data.vehicle.health)
        SetFuel(veh, data.fuel)
        SetVehicleOilLevel(veh, data.oil)
        QBCore.Functions.SetVehicleProperties(veh, data.vehicle.props)
    end, data.vehicle.coords, true)
    return tmpvehicle
end

-- Spawn 
local function Spawn(vehicleData, warp)
    local model = vehicleData.model
    ClearAreaOfVehicles(vehicleData.vehicle.coords.x, vehicleData.vehicle.coords.y, vehicleData.vehicle.coords.z, 2, false, false, false, false, false)
    Wait(30)
    local entity = VehicleSpawn(vehicleData, warp)
    local tmpBlip = nil
    if PlayerData.citizenid == vehicleData.citizenid then
        if Config.UseParkingBlips then
            tmpBlip = CreateParkedBlip(Lang:t('system.parked_blip_info',{modelname = vehicleData.modelname}), vehicleData.vehicle.location)
        end
        TriggerEvent('qb-parking:client:addkey', vehicleData.plate, vehicleData.citizenid) 
    end
    LocalVehicles[#LocalVehicles+1] = {
		entity      = entity,
		vehicle     = vehicleData.mods,
		plate       = vehicleData.plate,
        fuel        = vehicleData.fuel,
        oil         = vehicleData.oil, 
		citizenid   = vehicleData.citizenid,
		citizenname = vehicleData.citizenname,
		livery      = vehicleData.vehicle.livery,
		health      = vehicleData.vehicle.health,
		model       = vehicleData.model,
        modelname   = vehicleData.modelname,
		location    = vehicleData.vehicle.location,
        blip        = tmpBlip,
        isGrounded  = false,
    }
    Wait(10)
    if ParkAction then
		ParkAction = false
		if LastUsedPlate and vehicleData.plate == LastUsedPlate then
			TaskWarpPedIntoVehicle(PlayerPedId(), entity, -1)
			TaskLeaveVehicle(PlayerPedId(), entity)
			LastUsedPlate = nil
		end
    end
end

-- Draw 3d text on screen
local function Draw3DText(x, y, z, textInput, fontId, scaleX, scaleY)
    local p     = GetGameplayCamCoords()
    local dist  = #(p - vector3(x, y, z))
    local scale = (1 / dist) * 20
    local fov   = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    SetTextScale(scaleX * scale, scaleY * scale)
    SetTextFont(fontId)
    SetTextProportional(1)
    SetTextColour(250, 250, 250, 255)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(x, y, z + 2, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

--Display Parked Owner Text
local function DisplayParkedOwnerText()
    if Config.UseParkedVehicleNames then -- for performes
		local pl = GetEntityCoords(PlayerPedId())
		local displayWhoOwnesThisCar = nil
		for k, vehicle in pairs(LocalVehicles) do
			if #(pl - vector3(vehicle.location.x, vehicle.location.y, vehicle.location.z)) < Config.DisplayDistance then
				if PlayerData.job.name == "police" and PlayerData.job.onduty then
                    displayWhoOwnesThisCar = CreateParkDisPlay(vehicle, 'police')
					Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z + 0.2, displayWhoOwnesThisCar, 0, 0.04, 0.04)
                else
                    if PlayerData.citizenid == vehicle.citizenid then
                        displayWhoOwnesThisCar = CreateParkDisPlay(vehicle, 'citizen')
                        Draw3DText(vehicle.location.x, vehicle.location.y, vehicle.location.z + 0.2, displayWhoOwnesThisCar, 0, 0.04, 0.04)
                    end
                end
			end
		end
    end
end

-- Get the stored vehicle player is in
local function GetPlayerInStoredCar(player)
    local entity = GetVehiclePedIsIn(player)
    local findVehicle = false
    for i = 1, #LocalVehicles do
        if LocalVehicles[i].entity and LocalVehicles[i].entity == entity then
            findVehicle = LocalVehicles[i]
            break
        end
    end
    return findVehicle
end

-- Get the stored vehicle player is in
local function GetParkeddCar(vehicle)
    local findVehicle = false
    for i = 1, #LocalVehicles do
        if LocalVehicles[i].entity and LocalVehicles[i].entity == vehicle then
            findVehicle = LocalVehicles[i]
            break
        end
    end
    return findVehicle
end

-- Delete single vehicle
local function DeleteLocalVehicle(vehicle)
    IsDeleting = true
    if type(LocalVehicles) == 'table' and #LocalVehicles > 0 and LocalVehicles[1] then
		for i = 1, #LocalVehicles do
            if type(vehicle.plate) ~= 'nil' and type(LocalVehicles[i]) ~= 'nil' and type(LocalVehicles[i].plate) ~= 'nil' then
				if vehicle.plate == LocalVehicles[i].plate then
					DeleteEntity(LocalVehicles[i].entity)
                    table.remove(LocalVehicles, i)
				end
			end
		end
    end
    IsDeleting = false
end

-- Create Vehicle Park Target Zone
local function createVehParkingZone(model)
    if Config.UseTargetEye then
        exports['qb-target']:AddGlobalVehicle({
            options = {
                {
                    type = "client",
                    event = "qb-parking:client:parking",
                    icon = "fas fa-car",
                    label = Lang:t('info.park'),
                },
                {
                    type = "client",
                    event = "qb-parking:client:unparking",
                    icon = "fas fa-car",
                    label = Lang:t('info.drive'),
                },
            },
            distance = Config.InteractDistance
        })
    end
end

-- Spawn local vehicles(server data)
local function SpawnVehicles(vehicles)
    CreateThread(function()
		while IsDeleting do Wait(Config.TimeDelay) end
		if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
			for i = 1, #vehicles, 1 do
                SetEntityCollision(vehicles[i].vehicle, false, true)
                SetEntityVisible(vehicles[i].vehicle, false, 0)
				DeleteLocalVehicle(vehicles[i].vehicle)
                if Config.UseSpawnDelay then Wait(Config.SpawnTimeDelay) end
                Spawn(vehicles[i], false)
                createVehParkingZone()
			end
		end
    end)
end

-- Spawn single vehicle(client data)
local function SpawnVehicle(vehicleData)
    CreateThread(function()
        while IsDeleting do Wait(Config.TimeDelay) end
		if LocalPlayer.state.isLoggedIn then
            SetEntityCollision(vehicleData.vehicle, false, true)
            SetEntityVisible(vehicleData.vehicle, false, 0)
			DeleteLocalVehicle(vehicleData.vehicle)
            if Config.UseSpawnDelay then Wait(Config.SpawnTimeDelay) end
            Spawn(vehicleData, false)
		end
    end)
end

-- remove all Vehicles
local function RemoveVehicles(vehicles)
    IsDeleting = true
    if type(vehicles) == 'table' and #vehicles > 0 and vehicles[1] then
		for i = 1, #vehicles, 1 do
			local vehicle, distance = QBCore.Functions.GetClosestVehicle(vehicles[i].vehicle.location)
			if NetworkGetEntityIsLocal(vehicle) and distance < 1 then
				local driver = GetPedInVehicleSeat(vehicle, -1)
				if not DoesEntityExist(driver) or not IsPedAPlayer(driver) then
					local tmpModel = GetEntityModel(vehicle)
					SetModelAsNoLongerNeeded(tmpModel)
					DeleteEntity(vehicle)
					Citizen.Wait(300)
				end
			end
			vehicle, distance, driver, tmpModel = nil
		end
    end
    LocalVehicles = {}
    IsDeleting = false
end

-- Just some help text
local function DisplayHelpText(text)
    SetTextComponentFormat('STRING')
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

-- Delete the vehicle near the location
local function DeleteNearByVehicle(location)
    IsDeleting = true
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(location)
    if distance <= 1 then
        for i = 1, #LocalVehicles do
            if LocalVehicles[i].entity == vehicle then table.remove(LocalVehicles, i) end
            local tmpModel = GetEntityModel(vehicle)
            SetModelAsNoLongerNeeded(tmpModel)
            DeleteEntity(vehicle)
            tmpModel = nil
        end
    end
    IsDeleting = false
end

-- Drive 
local function Drive(player, vehicle, warp)
    ParkAction = 'drive'
    QBCore.Functions.TriggerCallback("qb-parking:server:drive", function(callback)
        if callback.status then
            QBCore.Functions.DeleteVehicle(vehicle.entity)
            QBCore.Functions.DeleteVehicle(GetVehiclePedIsIn(player))
            DeleteLocalVehicle(vehicle)
            DeleteNearByVehicle(vector3(vehicle.location.x, vehicle.location.y, vehicle.location.z))
            if Config.UseParkingBlips then RemoveBlip(vehicle.blip) end
            vehicle = false
            while IsDeleting do Wait(Config.SpawnTimeDelay) end
            local veh = VehicleSpawn(callback, warp)
            doCarDamage(veh, callback.vehicle.health)
            SetFuel(veh, callback.fuel)
            SetVehicleOilLevel(veh, callback.oil)
            FreezeEntityPosition(veh, false)
            SetEntityCanBeDamaged(veh, true)
            if warp then SetVehicleEngineOn(veh, true, true, true) end
        else
            QBCore.Functions.Notify(callback.message, "error", 5000)
        end
    end, vehicle)
end

-- Park
local function Park(player, vehicle, warp)
    if warp then
        SetVehicleEngineOn(vehicle, false, false, true)
        TaskLeaveVehicle(player, vehicle)
    end
    RequestAnimSet("anim@mp_player_intmenu@key_fob@")
    TaskPlayAnim(player, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false)
    Wait(2000)
    ClearPedTasks(player)
    SetVehicleLights(vehicle, 2)
    Wait(150)
    SetVehicleLights(vehicle, 0)
    Wait(150)
    SetVehicleLights(vehicle, 2)
    Wait(150)
    SetVehicleLights(vehicle, 0)
    TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 5, "lock", 0.2)
end

-- Send Email to the player phone
local function SendMail(mail_sender, mail_subject, mail_message)
    if Config.PhoneNotification then
        local coords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('qb-phone:server:sendNewMail', {
            sender  = mail_sender,
            subject = mail_subject,
            message = mail_message,
            button = {
                enabled = true,
                buttonEvent = "qb-parking:client:setParkedVecihleLocation",
                buttonData = coords
            }
        })
    end
end

-- Get the street name where you are at the moment.
local function GetStreetName()
    local ped       = PlayerPedId()
    local veh       = GetVehiclePedIsIn(ped, false)
    local coords    = GetEntityCoords(PlayerPedId())
    local zone      = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneLabel = GetLabelText(zone)
    local var       = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local hash      = GetStreetNameFromHashKey(var)
    local street    = nil
    if hash == '' then street = zoneLabel else street = hash..', '..zoneLabel end
    return street
end

-- Get Real Model Name Config.lua to add more
local function GetRealModel(vehicle)
    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    local currentModel = GetDisplayNameFromVehicleModel(vehicleProps["model"])
    if Config.Trailers[currentModel] then
        currentModel = Config.Trailers[currentModel].model
    end
    if Config.Vehicles[currentModel] then
        currentModel = Config.Vehicles[currentModel].model
    end
    return currentModel
end

-- Save
local function Save(player, vehicle, warp)
    local vehicleProps = QBCore.Functions.GetVehicleProperties(vehicle)
    QBCore.Functions.TriggerCallback('qb-garage:server:checkVehicleOwner', function(owned)
        if owned then
            Park(player, vehicle, warp)
            local displaytext  = GetDisplayNameFromVehicleModel(vehicleProps["model"])
            local carModelName = GetLabelText(displaytext)
            ParkAction         = 'park'
            LastUsedPlate      = plate
            local offset       = trailerOffset(vehicle)
            local currenModel  = GetRealModel(vehicle)
            QBCore.Functions.TriggerCallback("qb-parking:server:save", function(callback)
                if callback.status then
                    IsDeleting = true
                    QBCore.Functions.DeleteVehicle(vehicle)
                    SendMail(
                        Lang:t('mail.sender' , {
                            company   = Lang:t('info.companyName'),
                        }),
                        Lang:t('mail.subject', {
                            model     = carModelName,
                            plate     = LastUsedPlate,
                        }),
                        Lang:t('mail.message', {
                            street    = GetStreetName(),
                            company   = Lang:t('info.companyName'),
                            username  = PlayerData.charinfo.firstname,
                            model     = carModelName,
                            plate     = LastUsedPlate,
                        })
                    )
                    IsDeleting = false
                else
                    QBCore.Functions.Notify(callback.message, "error", 5000)
                end
            end, {
                props       = vehicleProps,
                livery      = GetVehicleLivery(vehicle),
                citizenid   = PlayerData.citizenid,
                plate       = vehicleProps.plate,
                fuel        = GetVehicleFuelLevel(vehicle),
                oil         = GetVehicleOilLevel(vehicle),
                model       = currenModel,
                modelname   = carModelName,
                health      = {engine = GetVehicleEngineHealth(vehicle), body = GetVehicleBodyHealth(vehicle), tank = GetVehiclePetrolTankHealth(vehicle) },
                location    = vector4(GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y, GetEntityCoords(vehicle).z - offset, GetEntityHeading(vehicle)),
                coords      = vector4(GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y, GetEntityCoords(vehicle).z - offset, GetEntityHeading(vehicle)),
            })
        else
            QBCore.Functions.Notify(Lang:t('info.must_own_car'), 'error')
            return
        end
    end, vehicleProps.plate)
end

-- Impound/Stolen/UnPark
local function ActionVehicle(plate, action)
    for i = 1, #LocalVehicles do
        if LocalVehicles[i].plate == plate then
            QBCore.Functions.TriggerCallback("qb-parking:server:vehicle_action", function(callback)
                if callback.status then
                    FreezeEntityPosition(LocalVehicles[i].entity, false)
                    if action == 'impound' then
                        DeleteEntity(LocalVehicles[i].entity)
                    end
                    table.remove(LocalVehicles, i)
                end
            end, LocalVehicles[i].plate, action)
        end
    end
end

local function IsNotReservedPosition(coords)
    freeSpot = true
    local haspaid  = false
    for _, data in pairs(Config.ReservedParkList) do
        if #(coords - data.coords) <= tonumber(data.radius) then
            if Config.IgnoreJobs[PlayerData.job.name] and PlayerData.job.onduty then
                freeSpot = true
            else
                if data.parktype == 'nopark' then
                    freeSpot = false
                else
                    if data.parktype == 'prived' then
                        if PlayerData.citizenid ~= data.citizenid then
                            freeSpot = false
                        end
                    end
                    if data.parktype == 'job' then
                        if not Config.IgnoreJobs[PlayerData.job.name] and not PlayerData.job.onduty then
                            freeSpot = false
                        end
                    end
                    if data.parktype == 'paid' then
                        QBCore.Functions.TriggerCallback("qb-parking:server:payparkspace", function(cb)
                            if cb.status then 
                                QBCore.Functions.Notify(cb.message, "primary", 3000)
                            else
                                freeSpot = false
                                QBCore.Functions.Notify(cb.message, "error", 3000)
                            end
                        end, data.cost)
                    end
                    if data.parktype == 'free' then
                        freeSpot = true
                    end
                    ParkOwnerName = data.name
                end
            end
        end
    end
   return freeSpot
end

local function DrawParkedLocation(coords)
    if Config.UseParkedLocationNames then
        for _, data in pairs(Config.ReservedParkList) do
            if Config.BuildMode then 
                extraRadius = tonumber(data.radius) + tonumber(Config.BuildModeDisplayDistance)
            else
                extraRadius = tonumber(data.radius) + tonumber(Config.DisplayMarkerDistance) 
            end
            if #(coords - data.coords) < tonumber(extraRadius) then
                if data.marker then
                    local vehicle, distance = QBCore.Functions.GetClosestVehicle(data.coords)
                    local r, g, b = 0, 0, 0
                    if data.parktype == 'paid' then
                        r, g, b = Config.ParkColours['blue'].r, Config.ParkColours['blue'].g, Config.ParkColours['blue'].b
                    elseif data.parktype == 'prived' then
                        if PlayerData.citizenid == data.citizenid then
                            r, g, b = Config.ParkColours['green'].r, Config.ParkColours['green'].g, Config.ParkColours['green'].b
                        else
                            r, g, b = Config.ParkColours['red'].r, Config.ParkColours['red'].g, Config.ParkColours['red'].b
                        end
                    elseif data.parktype == 'job' then
                        if Config.IgnoreJobs[PlayerData.job.name] and PlayerData.job.onduty then
                            r, g, b = Config.ParkColours['orange'].r, Config.ParkColours['orange'].g, Config.ParkColours['orange'].b
                        else
                            r, g, b = Config.ParkColours['black'].r, Config.ParkColours['black'].g, Config.ParkColours['black'].b
                        end
                    else
                        if data.parktype == 'free' then
                            r, g, b = Config.ParkColours['white'].r, Config.ParkColours['white'].g, Config.ParkColours['white'].b
                            if vehicle and distance <= 1 then
                                r, g, b = Config.ParkColours['green'].r, Config.ParkColours['green'].g, Config.ParkColours['green'].b
                            end
                        end
                    end
                    DrawMarker(2, data.markcoords.x, data.markcoords.y, data.markcoords.z + 1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15,r, g, b, 222, false, false, false, true, false, false, false)
                    if data.parktype ~= 'free' then
                        if data.parktype ~= 'nopark' and data.parktype ~= 'paid' then
                            Draw3DText(data.markcoords.x, data.markcoords.y, data.markcoords.z - 1.3, "~y~Reserved~s~", 0, 0.04, 0.04)
                        end
                        if PlayerData.citizenid ~= data.citizenid then
                            Draw3DText(data.markcoords.x, data.markcoords.y, data.markcoords.z - 1.4, "~y~".. data.display.."~s~", 0, 0.04, 0.04)
                        else
                            Draw3DText(data.markcoords.x, data.markcoords.y, data.markcoords.z - 1.4, "~b~".. data.display.."~s~", 0, 0.04, 0.04)
                        end
                    else
                        if data.parktype == 'free' then
                            Draw3DText(data.markcoords.x, data.markcoords.y, data.markcoords.z - 1.3, "~y~".. data.display.."~s~", 0, 0.04, 0.04)
                        end
                    end
                end
            end
        end
    end
end
-- Check Distance To Force Vehicle to the Ground
local function checkDistanceToForceGrounded(distance)
    if type(LocalVehicles) == 'table' and #LocalVehicles > 0 and LocalVehicles[1] then
        for i = 1, #LocalVehicles do
            if type(LocalVehicles[i]) ~= 'nil' and type(LocalVehicles[i].entity) ~= 'nil' then
                local tmp = LocalVehicles[i]
                if DoesEntityExist(LocalVehicles[i].entity) then
                    if #(GetEntityCoords(PlayerPedId()) - vector3(tmp.location.x, tmp.location.y, tmp.location.z)) < distance then
                        if not tmp.isGrounded then
                            local offset = trailerOffset(LocalVehicles[i].entity)
                            SetEntityCoords(tmp.entity, tmp.location.x, tmp.location.y, tmp.location.z - offset)
                            SetVehicleOnGroundProperly(tmp.entity)
                            LocalVehicles[i].isGrounded = true
                            --print("Parking Force Grounded - Plate ("..tmp.plate..") Model ("..tmp.modelname ..") Grounded ("..tostring(LocalVehicles[i].isGrounded)..") ")
                        end
                    else
                        LocalVehicles[i].isGrounded = false
                        --print("Parking Reset Grounded - Plate ("..tmp.plate..") Model ("..tmp.modelname..") Grounded ("..tostring(LocalVehicles[i].isGrounded)..") ")
                    end
                end
            end
        end
    end
end

-- Build Mode Create State
local function CreateState()
    if Config.BuildMode then
        local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), 0)
        local markerCoords = GetOffsetFromEntityInWorldCoords(currentVehicle, 0.0, 2.5 , -1.0)
        DrawMarker(2, markerCoords.x, markerCoords.y, markerCoords.z + 2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 0, 255, 26, 126, false, false, false, true, false, false, false)
        DrawMarker(27, markerCoords.x, markerCoords.y, markerCoords.z , 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 200, false, false, false, true, false, false, false)
		DrawMarker(1, markerCoords.x, markerCoords.y, markerCoords.z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 255, 0, 0, 200, false, false, false, true, false, false, false)
    end
end

-- NUI Menu
local function closeNUI()
    SetNuiFocus(false, false)
    SendNUIMessage({type = "newParkSetup", enable = false})
    Wait(10)
end

local function hideNUI()
    SetNuiFocus(false, false)
    SendNUIMessage({type = "hide"})
    Wait(1)
end

local function openNUI()
    SetNuiFocus(true, true)
    SendNUIMessage({type = "newDoorSetup", enable = true})
    Wait(1)
end

-- Commands
RegisterKeyMapping(Config.Command.park, Lang:t('system.park_or_drive'), 'keyboard', Config.KeyParkBindButton) 
RegisterKeyMapping(Config.Command.createmenu, Lang:t('system.open_create_menu'), 'keyboard', Config.KeyParkMenuBindButton) 


-- NUI Callbacks
RegisterNUICallback('newParkLocation', function(data, cb)
    closeNUI()
    cb('ok')
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
    local offset = 2.5
    local markerOffset = GetOffsetFromEntityInWorldCoords(vehicle, 0, offset, 0)
    Wait(200)
    TriggerServerEvent('qb-parking:server:AddNewParkingSpot', QBCore.Functions.GetPlayerData().source, data, markerOffset)
end)

RegisterNetEvent("qb-parking:client:openmenu", function(source)
    openNUI()
    SendNUIMessage({type = "newParkSetup", enable = true})
end)

RegisterNetEvent("qb-parking:client:closemenu", function(source)
    hideNUI()
    SendNUIMessage({type = "hide", enable = false})
end)

RegisterNUICallback('close', function(data, cb)
    closeNUI()
    cb('ok')
end)

-- Events
RegisterNetEvent("qb-parking:client:addVehicle", function(vehicle) SpawnVehicle(vehicle) end)
RegisterNetEvent("qb-parking:client:deleteVehicle", function(vehicle) DeleteLocalVehicle(vehicle) end)
RegisterNetEvent("qb-parking:client:impound",  function(plate) ActionVehicle(plate, 'impound') end)
RegisterNetEvent("qb-parking:client:stolen",  function(plate) ActionVehicle(plate, 'stolen') end)
RegisterNetEvent("qb-parking:client:unpark", function(plate) ActionVehicle(plate, 'unpark') end)

RegisterNetEvent("qb-parking:client:refreshVehicles", function(vehicles)
    GlobalVehicles = vehicles
    RemoveVehicles(vehicles)
    Wait(1000)
    SpawnVehicles(vehicles)
    Wait(1000)
end)

RegisterNetEvent("qb-parking:client:unparking", function()
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId())) 
    if distance <= Config.InteractDistance then
        Drive(PlayerPedId(), GetParkeddCar(vehicle), false)
        QBCore.Functions.Notify(Lang:t('info.has_take_the_car'), "success", 1000)
    else
        QBCore.Functions.Notify(Lang:t("system.to_far_from_vehicle"), "error", 2000)
    end
end)

RegisterNetEvent("qb-parking:client:parking", function()
    local vehicle, distance = QBCore.Functions.GetClosestVehicle(GetEntityCoords(PlayerPedId()))
    if distance <= Config.InteractDistance then
        if IsNotReservedPosition(GetEntityCoords(vehicle)) then
            Save(PlayerPedId(), vehicle, false)
            QBCore.Functions.Notify(Lang:t('success.parked'), "success", 1000)
        else
            QBCore.Functions.Notify(Lang:t('system.already_reserved'), "error", 5000)
        end
    else
        QBCore.Functions.Notify(Lang:t("system.to_far_from_vehicle"), "error", 2000)
    end
end)

RegisterNetEvent('qb-parking:client:setParkedVecihleLocation', function(location)
    SetNewWaypoint(location.x, location.y)
    QBCore.Functions.Notify(Lang:t("success.route_has_been_set"), 'success')
end)

RegisterNetEvent('qb-parking:client:addkey', function(plate, cid)
    if citizenid == 0 or citizenid == nil then
        citizenid = QBCore.Functions.GetPlayerData().citizenid
    end
    if citizenid == cid then 
        TriggerEvent('vehiclekeys:client:SetOwner', plate) 
    end
end)

-- Server To Client Events
RegisterNetEvent('qb-parking:client:newParkConfigAdded', function(parkname, data)
    Config.ReservedParkList[parkname] = data
    QBCore.Functions.Notify("New park configuration is addedd to the park list.", 'success')
end)

RegisterNetEvent("qb-parking:client:GetUpdate", function(state)
    UpdateAvailable = state
    if UpdateAvailable then print(Lang:t('system.update')) end
end)

RegisterNetEvent("qb-parking:client:park", function(state)
    isUsingParkCommand = true
end)

RegisterNetEvent("qb-parking:client:useparknames", function(state)
    Config.UseParkedVehicleNames = not Config.UseParkedVehicleNames
end)

RegisterNetEvent("qb-parking:client:useparkspotnames", function(state)
    Config.UseParkedLocationNames = not Config.UseParkedLocationNames
end)

RegisterNetEvent("qb-parking:client:usenotification", function(state)
    Config.PhoneNotification = not Config.PhoneNotification
end)

RegisterNetEvent("qb-parking:client:buildmode", function(state)
    Config.BuildMode = not Config.BuildMode
end)

-- Threads
CreateThread(function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

CreateThread(function()
    while true do
        if not Config.UseParkZones then
            local pl = GetEntityCoords(PlayerPedId())
            if #(pl - vector3(Config.ParkingLocation.x, Config.ParkingLocation.y, Config.ParkingLocation.z)) < Config.ParkingLocation.s then
                InParking = true
                crParking = 'allparking'
            end
        end
        if InParking then
            if not SpawnedVehicles then
                RemoveVehicles(GlobalVehicles)
                TriggerServerEvent("qb-parking:server:refreshVehicles", crParking)
                SpawnedVehicles = true
                Wait(2000)
            end
        else
            if SpawnedVehicles then
                RemoveVehicles(GlobalVehicles)
                SpawnedVehicles = false
            end
        end
        Wait(0)
    end
end)

CreateThread(function()
    if Config.UseParkingSystem then
		while true do
            local position = nil
			local player = PlayerPedId()
            CreateState()
            if IsPedInAnyVehicle(player) then
                position = GetEntityCoords(GetVehiclePedIsIn(player))
            else
                position = GetEntityCoords(player)
            end
            DrawParkedLocation(position)
			if InParking and IsPedInAnyVehicle(player) then
				local storedVehicle = GetPlayerInStoredCar(player)
				local vehicle = GetVehiclePedIsIn(player)
                local plate = QBCore.Functions.GetPlate(vehicle)
				if storedVehicle ~= false then
					DisplayHelpText(Lang:t("info.press_drive_car"))
					if IsControlJustReleased(0, Config.ParkingButton) then
						isUsingParkCommand = true
					end
				end
				if isUsingParkCommand then
					isUsingParkCommand = false
					if storedVehicle ~= false then
						Drive(player, storedVehicle, true)
					else
						if vehicle then
                            local speed = GetEntitySpeed(vehicle)
                            local vehicleCoords = GetEntityCoords(vehicle)
                            if speed > Config.MinSpeedToPark and Config.UseStopSpeedForPark then
                                QBCore.Functions.Notify(Lang:t("info.stop_car"), 'error', 1500)

                            elseif IsThisModelACar(GetEntityModel(vehicle)) or IsThisModelABike(GetEntityModel(vehicle)) or IsThisModelABicycle(GetEntityModel(vehicle)) then
                                if IsNotReservedPosition(vehicleCoords) then
                                    Save(PlayerPedId(), vehicle, true)
                                    QBCore.Functions.Notify(Lang:t("success.parked"), 'success', 1000)
                                else
                                    QBCore.Functions.Notify(Lang:t('system.already_reserved'), "error", 5000)
                                end
                            elseif IsThisModelABoat(GetEntityModel(vehicle)) or IsThisModelAHeli(GetEntityModel(vehicle)) or IsThisModelAPlane(GetEntityModel(vehicle)) then
                                if IsNotReservedPosition(vehicleCoords) then
                                    Save(PlayerPedId(), vehicle, true)
                                    QBCore.Functions.Notify(Lang:t("success.parked"), 'success', 1000)
                                else
                                    QBCore.Functions.Notify(Lang:t('system.already_reserved'), "error", 5000)
                                end
                            end	
  
						end
					end
				end
			else
				isUsingParkCommand = false
			end
			Wait(0)
		end
    end
end)

CreateThread(function()
    if Config.UseParkingSystem and Config.UseParkedVehicleNames then
        while true do
            DisplayParkedOwnerText()
            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        checkDistanceToForceGrounded(Config.ForceGroundedDistane)
        Wait(Config.ForceGroundenInMilSec)
    end
end)

if Config.UseParkZones then
    for k, v in pairs(Config.Parkzones) do
        ParkZones[#ParkZones + 1] = PolyZone:Create({table.unpack(v.zones)}, { name = v.name })
    end
    combo = ComboZone:Create(ParkZones, { name = "parkCombo", debugPoly = Config.DebugPolyzone })
    CreateThread(function()
        Wait(500)
        while true do
            if LocalPlayer.state.isLoggedIn then
                local pos = GetEntityCoords(PlayerPedId())
                local isPointInside = combo:isPointInside(pos)
                Config.UseParkedLocationNames = combo:isPointInside(pos)
                Config.UseParkedVehicleNames = combo:isPointInside(pos)
                InParking = combo:isPointInside(pos)
            end
            Wait(1000)
        end
    end)
end

CreateThread(function()
    if Config.UseParkZones then
        for k, v in pairs(Config.Parkzones) do
            if v.showBlip then
                local Parking = AddBlipForCoord(v.enter)
                SetBlipSprite(Parking, 357)
                SetBlipDisplay(Parking, 4)
                SetBlipScale(Parking, 0.7)
                SetBlipAsShortRange(Parking, true)
                SetBlipColour(Parking, 3)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentSubstringPlayerName(v.name)
                EndTextCommandSetBlipName(Parking)
            end
        end
    end
end)
