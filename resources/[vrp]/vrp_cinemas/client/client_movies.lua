vRPserver = Tunnel.getInterface("vRP", "vrp_cinema_client")
vRP = Proxy.getInterface("vRP")
local GUI = {}
GUI.Time = 0
----------------------------------------------------------
---------------------load movie settings------------------
----------------------------------------------------------
-- Configure the opening hours
local openingHour = 0
local closingHour = 22
local currentcinema
local movie_choosed

-- Configure the coordinates for all the cinemas
local cinemaLocations = {
  { ['name'] = "Downtown", ['x'] = 300.788, ['y'] = 200.752, ['z'] = 104.385},
  { ['name'] = "Morningwood", ['x'] = -1423.954, ['y'] = -213.62, ['z'] = 46.5},
  { ['name'] = "Vinewood",  ['x'] = 302.907, ['y'] = 135.939, ['z'] = 160.946},
  { ['name'] = "Pillbox", ['x'] = 396.538, ['y'] =-713.026, ['z'] = 29.285},
}
--adds blips for movie theater
local blipsLoaded = false
local MovieState = false

function LoadBlips()
  for k,v in ipairs(cinemaLocations) do
    local blip = AddBlipForCoord(v.x, v.y, v.z)
    SetBlipSprite(blip, 135)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 25)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Biograf")
    EndTextCommandSetBlipName(blip)
--loads the theater interior
    RequestIpl("v_cinema")
    blipsLoaded = true
  end
end
------------------------------------------------------------
---------------------set up movie---------------------------
------------------------------------------------------------
function SetupMovie()
  cinema = GetInteriorAtCoords(320.217, 263.81, 82.974)
  LoadInterior(139521)
--this gets the hash key of the cinema screen
  cin_screen = GetHashKey("v_ilev_cin_screen")
   if not DoesEntityExist(tv) then
     tv = CreateObjectNoOffset(cin_screen, 320.1257, 248.6608, 86.56934, 1, true, false)
	 SetEntityHeading(tv, 179.99998474121)
    else 
	 tv = GetClosestObjectOfType(319.884, 262.103, 82.917, 20.475, cin_screen, 0, 0, 0)
   end
--this checks if the rendertarget is registered and  registers rendertarget
  if not IsNamedRendertargetRegistered("cinscreen") then
    RegisterNamedRendertarget("cinscreen", 0)
  end
--this checks if the screen is linked to rendertarget and links screen to rendertarget
    if not IsNamedRendertargetLinked(cin_screen) then
        LinkNamedRendertarget(cin_screen)
    end
  rendertargetid = GetNamedRendertargetRenderId("cinscreen")
--this checks if the rendertarget is linked AND registered 
  if IsNamedRendertargetLinked(cin_screen) and IsNamedRendertargetRegistered("cinscreen") then
--this sets the rendertargets channel and video
	Citizen.InvokeNative(0x9DD5A62390C3B735, 2, movie_choosed, 0)
--this sets the rendertarget	
	SetTextRenderId(rendertargetid)
--duh sets the volume
	SetTvVolume(100)	
--duh sets the cannel
    SetTvChannel(2)
--duh sets subtitles
    EnableMovieSubtitles(1)
--these are for the rendertarget 2d settings and stuff	
    Citizen.InvokeNative(0x67A346B3CDB15CA5, 100.0)
    Citizen.InvokeNative(0x61BB1D9B3A95D802, 4)
    Citizen.InvokeNative(0xC6372ECD45D73BCD, 1)
  else 
--this puts the rendertarget back to regular use(playing)
   SetTextRenderId(GetDefaultScriptRendertargetRenderId())
  end
  if MovieState == false then
    MovieState = true
    CreateMovieThread()
  end
end

function helpDisplay(text, state)
  SetTextComponentFormat("STRING")
  AddTextComponentString(text)
  DisplayHelpTextFromStringLabel(0, state, 0, -1)
end

--this FUNCTION deletes the movie screen sets the channel to basicly nothing
function DeconstructMovie()
 local obj = GetClosestObjectOfType(319.884, 262.103, 82.917, 20.475, cin_screen, 0, 0, 0)
  cin_screen = GetHashKey("v_ilev_cin_screen")
  SetTvChannel(-1)  
  ReleaseNamedRendertarget(GetHashKey("cinscreen"))
  SetTextRenderId(GetDefaultScriptRendertargetRenderId())
  SetEntityAsMissionEntity(obj,true,false)
  DeleteObject(obj)
end

--this FUNCTION is what draws the tv channel(needs to be in a loop)
function StartMovie()
    DrawTvChannel(0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
end

--this starts the movie
function CreateMovieThread()
  Citizen.CreateThread(function()
    SetTextRenderId(GetNamedRendertargetRenderId("cinscreen"))
	Citizen.InvokeNative(0x9DD5A62390C3B735, 2, movie_choosed, 0)	
	SetTvChannel(2)
	EnableMovieSubtitles(1)
	Citizen.InvokeNative(0x67A346B3CDB15CA5, 100.0)
    Citizen.InvokeNative(0x61BB1D9B3A95D802, 4)
    Citizen.InvokeNative(0xC6372ECD45D73BCD, 1)		
    while(true) do
      Citizen.Wait(0)
      StartMovie()
    end
  end)
end

function buy_ticket()
	TriggerServerEvent("vrp_cinema:showmenu")
end

--this is the enter theater stuff
function IsPlayerInArea()
  playerPed = GetPlayerPed(-1)
  playerCoords = GetEntityCoords(playerPed, true)
  hour = GetClockHours()
  for k,v in ipairs(cinemaLocations) do
-- Check if the player is near the cinema
        if GetDistanceBetweenCoords(playerCoords, v.x, v.y, v.z) < 4.8 then
-- Check if the cinema is open or closed.
          if hour < openingHour or hour > closingHour then
			helpDisplay("Biografen har ??ben mellem 01:00 og 22:00.", 0)
          else
			helpDisplay("[~b~E~w~] for at se film.", 0)
-- Check if the player is near the cinema and pressed "INPUT_CONTEXT"
			if IsControlJustReleased(0, 38) then
				currentcinema = v.name
				buy_ticket()
           end
          end
        end
      end
end
				
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    IsPlayerInArea()
  end
end)

--if the player is not inside theater delete screen
Citizen.CreateThread(function()
 if GetRoomKeyFromEntity(PlayerPedId()) ~= -1337806789 and DoesEntityExist(GetClosestObjectOfType(319.884, 262.103, 82.917, 20.475, cin_screen, 0, 0, 0)) then
    DeconstructMovie() 
 end
-- Create the blips for the cinema's
  LoadBlips()      
end)

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)
    playerPed = GetPlayerPed(-1)   
--if player hits "E" key while in theater they exit
	  if IsControlPressed(0, 38) and GetRoomKeyFromEntity(PlayerPedId()) == -1337806789 then
	DoScreenFadeOut(1000)
		if currentcinema == "Downtown" then
			SetEntityCoords(playerPed, 297.891, 193.296, 104.344, 161.925)
		elseif currentcinema == "Morningwood" then
			SetEntityCoords(playerPed, -1421.356, -198.388, 47.28, 350.0)
		elseif currentcinema == "Vinewood" then
			SetEntityCoords(playerPed, 303.278, 142.258, 103.846, 350.0)
    elseif currentcinema == "Pillbox" then
      SetEntityCoords(playerPed, 397.703,-707.013,29.283, 350.0)
		end
	Citizen.Wait(30)		
	DoScreenFadeIn(800)
	--
	TriggerEvent('GetOutCinema')
	--
	FreezeEntityPosition(GetPlayerPed(-1), 0)
	SetFollowPedCamViewMode(fistPerson)
	DeconstructMovie()
        MovieState = false
      end
    if GetRoomKeyFromEntity(PlayerPedId()) == -1337806789 then
	 SetPlayerInvincible(PlayerId(), true)
     	 SetCurrentPedWeapon(PlayerPedId(), GetHashKey("weapon_unarmed"), 1)
	 SetFollowPedCamViewMode(4)
	end 
    end
end)

			
RegisterNetEvent("vrp_cinema:movie")
AddEventHandler("vrp_cinema:movie", function (data)
	local _data = data 
	movie_choosed = _data
	DoScreenFadeOut(1000)
	SetupMovie()
	Citizen.Wait(500)
	SetEntityCoords(playerPed, 320.217, 263.81, 81.974, true, true, true, true)
	DoScreenFadeIn(800)
	Citizen.Wait(30)
	TriggerEvent('EnteringInCinema')
	SetEntityHeading(playerPed, 180.475)
	TaskLookAtCoord(GetPlayerPed(-1), 319.259, 251.827, 85.648, -1, 2048, 3)
	--FreezeEntityPosition(GetPlayerPed(-1), 1)	
	SetNotificationTextEntry('STRING')
	AddTextComponentString("[~b~E~w~] for at forlade biografen.")
	DrawNotification(false, false)
end)

