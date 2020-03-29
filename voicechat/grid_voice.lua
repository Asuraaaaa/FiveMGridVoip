local currentprox = 1
local proximity = {}
local displayproximity = 0
local dpcd = 5000
local v_pressed = 0

proximity[1] = {"WHISPER", 5.00, "VOIP: [•]"}
proximity[2] = {"NORMAL", 10.00, "VOIP: [••]"}
proximity[3] = {"SHOUT", 20.00, "VOIP: [•••]"}

local prox = proximity[2]

RegisterKeyMapping('voiceup', 'Voice Volume Increase', 'keyboard', 'pageup')
RegisterKeyMapping('voicedown', 'Voice Volume Decrease', 'keyboard', 'pagedown')
RegisterKeyMapping('voicechange', 'Voice Volume Cycle', 'keyboard', 'f11')

RegisterCommand("voiceup", function(source, args, rawCommand)
voiceprocess(1, false)
end)

RegisterCommand("voicedown", function(source, args, rawCommand)
voiceprocess(-1, false)
end)

RegisterCommand("voicechange", function(source, args, rawCommand)
voiceprocess(1, true)
end)

function voiceprocess(val, tgl)
  if tgl then
    currentprox = currentprox +1
    if not proximity[currentprox] then
      currentprox = 1
    end
  else
    currentprox = currentprox+val
    if currentprox < 1 then
      currentprox = 1
    elseif currentprox > #proximity then
      currentprox = #proximity
    end
  end
  prox = proximity[currentprox]
  displayproximity = dpcd
end

function displayText(text, red, green, blue, alpha, posx, posy, scale)
  SetTextFont(4)
  SetTextScale(scale, 0.5)
  SetTextWrap(0.0, 1.0)
  SetTextScale(0.5, scale)
  SetTextColour(red, green, blue, alpha)
  SetTextOutline()
  BeginTextCommandDisplayText("STRING") -- old: SetTextEntry()
  AddTextComponentSubstringPlayerName(text) -- old: AddTextComponentString
  EndTextCommandDisplayText(posx, posy) -- old: DrawText()
end

Citizen.CreateThread(function()
while true do
  Wait(0)
  if displayproximity >0 then
    displayproximity = displayproximity -100
    displayText("RANGE: "..prox[1], 255, 255, 255, 150, 0.011, 0.033, 0.45)
  end
  if v_pressed > 0 then
    v_pressed = v_pressed - 100
  end
  if IsControlPressed(1,249) then --push to talk is pressed
    if prox == proximity[#proximity] then
      displayText(prox[3], 230, 0, 0, 200, 0.011, 0.0085, 0.3)
    else
      displayText(prox[3], 0, 230, 0, 200, 0.011, 0.0085, 0.3)
    end
  end
  if IsControlJustPressed(1,20) then
    if v_pressed <= 0 then
      voiceprocess(1, true)
      v_pressed = 1000
    end
  end
end
end)

local currentGrid = 0
local driverfix

Citizen.CreateThread(function()
while true do
  Wait(0)
  local voiprange = prox[2]
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    voiprange = voiprange + 5 --Because in vehicles you wont be able to hear others while driving very fast
  end
  NetworkSetTalkerProximity(voiprange)
end
end)

function getGrid(x)
  return math.floor((x+8200) /1024) --Slice the map along the x axis into "grids"
end

Citizen.CreateThread(function()
  driverfix = false
  while true do
    Wait(100)
    local coords = GetEntityCoords(PlayerPedId())
    local newGrid = getGrid(coords.x)
    if newGrid ~= currentGrid then --In a new grid, change targets
      currentGrid = newGrid
      setAllTargets()
      TriggerServerEvent("ResyncChannel", currentGrid)
    end
  end
end)

function setAllTargets()
  NetworkClearVoiceChannel()
  Wait(500)
  NetworkSetVoiceChannel(currentGrid)
  Wait(500)
  MumbleSetVoiceTarget(0)
  MumbleSetVoiceTarget(currentGrid)
  MumbleClearVoiceTarget(currentGrid)
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid) --Add own grid to voip target list
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid+1) --Add sourrounding grid to voip target list
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid-1) --Add sourrounding grid to voip target list
end

RegisterCommand("voipfix", function() --if after a resource reload or after a voip restart through the settings you failed to join a channel, this will fix you if you
  setAllTargets()
end, false)

RegisterNetEvent("C_ResyncChannel") --since you cant add a non existent channel as voip target, we will have to resync surrounding targets once a new channel is created.
AddEventHandler("C_ResyncChannel", function(channelID)
if channelID ~= currentGrid and ((channelID == currentGrid +1) or (channelID == currentGrid -1)) then
  MumbleSetVoiceTarget(0)
  MumbleSetVoiceTarget(currentGrid)
  MumbleClearVoiceTarget(currentGrid)
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid) --Add own grid to voip target list
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid+1) --Add sourrounding grid to voip target list
  MumbleAddVoiceTargetChannel(currentGrid, currentGrid-1) --Add sourrounding grid to voip target list
end
end)
