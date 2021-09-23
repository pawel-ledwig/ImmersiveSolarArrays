ISMoveableSpriteProps.originalPlaceMoveableFunction = ISMoveableSpriteProps.placeMoveable -- we save the original function so we can run it as well as our code
function ISMoveableSpriteProps:placeMoveable( _character, _square, _origSpriteName ) -- we override the original function so our code runs whenever this runs.
  -- depending on when you want to do something, either run the original now, or after your code. In this example original is ran first
  local res = self:originalPlaceMoveableFunction(_character, _square, _origSpriteName) -- you may have to actually pass the parameters directly instead of self. Unsure here as i didn't test it, but one of the two should work
  if res == nil and self.isMoveable then
    -- Your stuff here example below
    if _origSpriteName == "solarmod_tileset_01_0" then
      _character:Say("Cool, a battery bank! Is it shiny?")
	  solarscan(_square, true, true, true, 0)
    end
	if _origSpriteName == "solarmod_tileset_01_6" or _origSpriteName == "solarmod_tileset_01_7" or _origSpriteName == "solarmod_tileset_01_8" or _origSpriteName == "solarmod_tileset_01_9" or _origSpriteName == "solarmod_tileset_01_10" then  
	   _character:Say("AAAAAA! Shiny solar panels")
	   solarscan(_square, true, false, true, 0)
	end
	
  else
    return res
  end
end


ISMoveableSpriteProps.originalpickUpMoveableFunction = ISMoveableSpriteProps.pickUpMoveable

function ISMoveableSpriteProps:pickUpMoveable( _character, _square, _createItem, _forceAllow) -- we override the original function so our code runs whenever this runs.
  -- depending on when you want to do something, either run the original now, or after your code. In this example original is ran first
  local res = self:originalpickUpMoveableFunction( _character, _square, _createItem, _forceAllow ) -- you may have to actually pass the parameters directly instead of self. Unsure here as i didn't test it, but one of the two should work
	if res ~= nil and self.isMoveable then
	-- local item = self.spriteName;
    -- Your stuff here example below
	local _spriteName = self.spriteName
    if _spriteName == "solarmod_tileset_01_0" then
      _character:Say("oo, heavy")
	  solarscan(_square, false, true, true, 0)
    end
	if _spriteName == "solarmod_tileset_01_6" or _spriteName == "solarmod_tileset_01_7" or _spriteName == "solarmod_tileset_01_8" or _spriteName == "solarmod_tileset_01_9" or _spriteName == "solarmod_tileset_01_10" then  
	   _character:Say("must not trip over, must not trip over")
	   solarscan(_square, false, false, true, 0)
	end
	
  else
    return res
  end
end

function solarscan(square, AddBool, IsBank, InitialScan, backupgenerator)
--square is the square of the solar panel, increment, AddBool is whether we should add (true) or remove a solar panel, IsBank: false if scan is coming from solar panel, true if coming from a battery bank, initial scan true when object first placed
--backupgenerator is normally 0, 1 wehn turning on a generator and 2 when turning off one
local n = square:getX() - 20;
local n2 = square:getX() + 20;
local n3 = square:getY() - 20;
local n4 = square:getY() + 20;
local bottom = math.max(0, square:getZ() - 3);
local top = math.min(8, square:getZ() + 3);
print("minmax")
print(bottom)
print(top)
for x = bottom, top do
	for j = n, n2 do
		for k = n3, n4 do
			if IsoUtils.DistanceToSquared(j + 0.5, k + 0.5, square:getX() + 0.5, square:getY() + 0.5) <= 400.0 then
			local mysquare = square:getCell():getGridSquare(j, k, x);
				if mysquare ~= nil then
				if IsBank == true then
				--scan coming from power bank
					if InitialScan == true then
					--power bank has just been added, do what is necessary
					else
					--periodic scan goes here. Recalculate solar panel, battery capacity and power usage stats,  note that there can be several panels in one square
					-- use 	ISMoveableSpriteProps:getSpecificMoveableObjectFromSquare( _square, _objectType )
					end
				
				end
				if IsBank == false then
				--scan coming from solar panel
					if AddBool == true then
					--solar panel should be added to power bank stats here,
					--use 	ISMoveableSpriteProps:getSpecificMoveableObjectFromSquare( _square, _objectType )
					else
					--solar panel should be removed from solar panel stats here
					-- use	ISMoveableSpriteProps:getSpecificMoveableObjectFromSquare( _square, _objectType )
					end
				end

				-- test function mysquare:AddWorldInventoryItem("Base.Money" ,0.5,0.5,0);
				-- print(mysquare)
				end
			end
		end
	end

end

end

--unimplemented untested below, add this to the scan.

--local powerconsumption = 0;

--[[
for ( objs = 0, square:getObjects():size()) do
	local isoObject = (IsoObject)square:getObjects():get(objs);
	if (isoObject ~= nil) then
		if instanceof(isoObject, "IsoWorldInventoryObject") == false then
			if instanceof(isoObject, "IsoTelevision") and isoObject:getDevicedata():getIsTurnedOn() then
			powerconsumption = powerconsumption + 0.03
			end
			if instanceof(isoObject, "IsoRadio") and isoObject:getDevicedata():getIsTurnedOn() then
			powerconsumption = powerconsumption + 0.01
			end
			if instanceof(isoObject, "IsoStove") and isoObject.oven:Activated() then
			powerconsumption = powerconsumption + 0.09
			end
			local b = isoObject:getContainerByType("fridge") ~= nil;
			local b2 = = isoObject:getContainerByType("freezer") ~= nil;
			if b and b2 then
			powerconsumption = powerconsumption + 0.13
			elseif b or b2 then
			powerconsumption = powerconsumption + 0.08
			end
			if instanceof(isoObject, "IsoLightSwitch") and isoObject:isActivated() then
			powerconsumption = powerconsumption + 0.002
			end
		end
	end
end

]]--

-- pass powerconsumption to power bank
--power consumption of a freezer is around 350 watts
--power production of a 1x1 meter solar panels is around 1000 watts, maybe 750 in the 90's
--this should mean you can run a freezer continuously with one solar panel, given enough batteries
--batteries ah-range: standard 50Ah, Sport: 75Ah, Heavy-Duty 100Ah, deep cycle 200Ah
--you'd need around 1800Ah for the freezer assuming mixed battery types, 
--which means you'd need an almost fully upgraded battery bank using heavy-duty batteries