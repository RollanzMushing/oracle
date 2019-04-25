-- Based on the wonderful apt module by Alyxeri --
-- https://forums.achaea.com/discussion/5974/apt-a-almost-trigger-less-ndb#latest

function ndbEcho(msg)
	Note("[ndb]: " .. msg)
end -- function

function ndbLoadSettings()
	-- If already loaded, then ignore
	if ndb then return false end

	local ndbData = savedir.."/ndb.ach"
	if (fileExists(ndbData)) == false then
		return false
	end -- if

	ndb = ndb or {}
	ndb.players = ndb.players or {}
	ndbDir = savedir.."/ndbFiles"
	table.load(ndbData)

	ndbEcho("Name database loaded successfully.")
end -- function

function ndbSaveSettings()
	table.save("ndb", ndb)
	ndbEcho("ndb database saved successfully.")
end -- function

function ndbInstall()
	if (fileExists(ndbData)) == true then
		ndbEcho("Previous ndb installation detected.")
		return
	end -- if

	ndb = {}
	ndb.installed = true
	ndb.players = {}
	ndbEcho("ndb database initialized.")
end -- function

function ndbDownload(person)
	assert(person)
	local person = person:title()
	utils.shellexecute ("wget", 
                    "https://api.achaea.com/characters/" .. person .. ".json -O " .. 
                     ndbDir .. "/" .. person .. ".json")
end -- function

function ndbLoad(person)
	assert(person)
	local t = {}
	local f, s = assert(io.open(ndbDir.."/"..person, "rb"))
	if f then s = f:read("*all")
    f:close()
	end -- if

	-- didn't get JSON data? 
	if s:find("Internal error", 1, true) or s:find("DOCTYPE html PUBLIC", 1, true) then
		ndbEcho("Data Acquisition Failed!") 
		return

	end



local t = json.decode(s)
local cities = {"Ashtan", "Cyrene", "Eleusis", "Hashan", "Mhaldor", "Targossas"}
	local name = t.name
	local title = t.fullname
	local class = t.class:title()
	local house = t.house
	local city = t.city
	local level = tonumber(t.level)
	local xprank = tonumber(t.xp_rank)

	local tmpCity = (ndb.players[name] and ndb.players[name].city or "Unknown")

	ndb.players[name] = {
		name = name,
		title = title,
		class = class,
		level = level,
		xprank = xprank,
	}

	if house:find("hidden") then
		ndb.players[name].house = "Unknown"
	elseif house:find("none") then
		ndb.players[name].house = "None"
	else
		ndb.players[name].house = house:title()
	end

	if city:find("hidden") then
		if not table.contains(cities, tmpCity) then
			ndb.players[name].city = "Unknown"
			if honoursPerson == nil then ndbEcho("WARNING: "..name.."'s city is hidden; will require a manual honours/setting to update it.") end
		else
			ndb.players[name].city = tmpCity
		end
	elseif city:find("none") then
		ndb.players[name].city = "None"
	else
		ndb.players[name].city = city:title()
	end

  	os.remove(ndbDir.."/"..person)

	if honoursPerson ~= nil then 
		Send("honours "..honoursPerson)
	end -- if
end -- function

function ndbUpdate()
	local t = utils.readdir(ndbDir.."\\*.json")
	if t == nil then ndbEcho("No names to add!") return end
	assert(t)
	for k, v in pairs(t) do
		ndbLoad(k)
	end -- for
end -- function

function ndbGetInfo(names)
	-- parse list to see who isn't tracked
	for _, name in pairs(names) do
		if not ndbExists(name) then
			ndbDownload(name)
		end -- if
	end -- for
	-- ndbUpdate()
	ndbEcho("Database has been fully updated, thank you.")
end -- function

function ndbExists(name)
	if not ndb.players[name] then
		return false
	else
		return true
	end -- if
end -- function
