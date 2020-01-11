-- Basic "good enough" for now
local function tprint(t)
	for i,v in pairs(t) do
		if type(v) == "table" then
			tprint(v)
		else
			print(i,v)
		end
	end
end

-- Translates 'transporter_7' into an OpenComputers ID String
local function resolvePeripheralName(name)
	local i = string.match(name, "_([0-9]*)$")
	return peripheral.getNames()[tonumber(i)]
end

-- Adds siblings to all transposer.getStackInSlot(1, ...)-like functions
-- as transposer.getStackInSlot.minecraft_chest(...) shortcuts
--
-- Just a matter of preference
local function populateTransposer(side)
	local transposer = peripheral.wrap(side)
	local methods = {}
	for i,v in pairs(transposer) do
		if type(v) == "function" then
			methods[i] = true
		end
	end

	-- Creates a transposer object 
	-- with several sub 
	for i=0,5 do
		local realName = transposer.getInventoryName(i)

		if realName ~= nil then
			local name = string.gsub(realName, ":", "_")
			-- this solution was nice but screwed with the autocompletion
			-- local tmp = setmetatable({}, {
			-- 	__index = function(ref, key) 
			-- 		return function(...) print('calling ' .. key) return transposer[key](i, ...) end
			-- 	end
			-- })
			local tmp = {}
			for key,v in pairs(methods) do
				tmp[key] = function(...) return transposer[key](i, ...) end
			end

			if transposer[name] == nil then
				transposer[name] = tmp
			else
				transposer[name..'_'..i] = tmp
			end
		end
	end

	return transposer
end

-- Wrapper for peripheral.wrap that understands the "transposer_n" names instead
-- of OpenComputers IDs
function wrap(side)
	local ptype = peripheral.getType(side)
	if ptype == nil then
		side = resolvePeripheralName(side)
		if side == nil then return nil end
		ptype = peripheral.getType(side)
	end

	if ptype == "transposer" then
		return populateTransposer(side)
	else
		return peripheral.wrap(side)
	end
end

-- Returns both the regular peripheral.getNames() content but makes an effort
-- to properly name the peripherals instead of using OpenComputers IDs
function getNames()
	--	local count = {}
	local names = peripheral.getNames()
	local p = peripheral.getNames()
	local size = #p

	for i,v in pairs(names) do
		local ptype = peripheral.getType(v)
		
		if ptype ~= "relay" then
			--	if count[ptype] then 
			--		count[ptype] = count[ptype]+1
			--	else
			--		count[ptype] = 0
			--	end

			table.insert(p, ptype..'_'..i)
		end
	end

	return p
end

-- Wrapping by type
-- ex: wrapAny("me_interface")
function wrapAny(ptypeWanted)
	local names = peripheral.getNames()

	for i,v in pairs(names) do
		local ptype = peripheral.getType(v)
		if ptype == ptypeWanted then
			return wrap(v)
		end
	end

	return nil
end
