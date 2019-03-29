local baitcar = nil
local baitplate = nil
local baitblip = nil
local playerPed = PlayerPedId()

RegisterCommand('baitcar', function(source, args)
    -- account for the argument not being passed
    local vehicleName = args[1] or 'adder'

    if baitcar and DoesEntityExist(baitcar) then
        print("You already have a bait car " .. baitplate)
        FlashBlip(baitblip)
        return
    end
    -- check if the vehicle actually exists
    if not IsModelInCdimage(vehicleName) or not IsModelAVehicle(vehicleName) then
        TriggerEvent('chat:addMessage', {
            args = { 'It might have been a good thing that you tried to spawn a ' .. vehicleName .. '. Who even wants their spawning to actually ^*succeed?' }
        })
        return
    end

    -- load the model
    RequestModel(vehicleName)

    -- wait for the model to load
    while not HasModelLoaded(vehicleName) do
        Wait(500)
    end

    local pos = GetEntityCoords(playerPed) -- get the position of the local player ped

    -- create the vehicle
    baitcar = CreateVehicle(vehicleName, pos.x, pos.y, pos.z, GetEntityHeading(playerPed), true, false)
    baitplate = GetVehicleNumberPlateText(baitcar)
    print("Spawned baitcar " .. baitplate)
    -- netid = VehToNet(bait['vehicle'])
    
    -- set the player ped into the vehicle's driver seat
    SetPedIntoVehicle(playerPed, baitcar, -1)

    -- release the model
    SetModelAsNoLongerNeeded(vehicleName)

    baitblip = BlipBaitcar(baitcar)
    
    SetBait(baitcar)
end, false)

RegisterCommand('impound', function(source, args)
    local coordFrom = GetEntityCoords(PlayerPedId(), true)
    local coordTo = GetOffsetFromEntityInWorldCoords(playerPed, 0, 30.0, 5)
    local RayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 2, playerPed, 0)
    local _, _, _, _, targetVehicle = GetRaycastResult(RayHandle)

    if targetVehicle == 0 then
        print('No vehicle found. Face vehicle to impound')
    elseif IsPedInVehicle(targetVehicle) then
        print('Vehicle occupied')
    else
        SetEntityAsMissionEntity(targetVehicle) -- used to force vehicle to delete immediately, otherwise it looks like game will decide when to delete
        DeleteVehicle(targetVehicle)
    end
end, false)

-- RegisterCommand("imp", function(source, args)
--     SetEntityAsMissionEntity(baitcar) -- used to force vehicle to delete immediately, otherwise it looks like game will decide when to delete
--     DeleteVehicle(baitcar)
-- end)

function SetBait(vehicle)
    Citizen.CreateThread(function()
        -- this first loop will check for owner of baitcar since he is immediately placed inside
        while IsPedInVehicle(vehicle) do
            if not DoesEntityExist(vehicle) then
                return
            end
            Citizen.Wait(2000) -- wait for owner to leave to prime the car
        end
        SetVehicleDoorsLocked(vehicle, 4)
        TriggerEvent('chat:addMessage', {
            args = { 'Bait car is primed!' }
        })
        -- check if someone stole vehicle
        while not IsPedInVehicle(vehicle) do
            if not DoesEntityExist(vehicle) then
                return
            end
            Citizen.Wait(2000)
        end
        print("bait took!")
        Citizen.Wait(15000)
        SetVehicleDoorsLocked(vehicle, 4)
        SetVehicleUndriveable(vehicle, true)
    end)
end

function IsPedInVehicle(vehicle)
    max_passengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for i=-2, max_passengers do
        if GetPedInVehicleSeat(vehicle, i) ~= 0 then
            return true
        end
    end
    return false
end

function BlipBaitcar(vehicle)
    -- blip the vehicle as baitcar
    AddTextEntry('BLIP_BAIT', '~a~')
    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, 326) -- car sprite

    BeginTextCommandSetBlipName("STRING");
    AddTextComponentString("Baitcar")
    EndTextCommandSetBlipName(blip)

    SetBlipColour(blip, 1) -- red blip
    return blip
end

function FlashBlip(blip)
    Citizen.CreateThread(function()
        SetBlipFlashes(blip, true)
        Citizen.Wait(5000)
        SetBlipFlashes(blip, false)
    end)
end
