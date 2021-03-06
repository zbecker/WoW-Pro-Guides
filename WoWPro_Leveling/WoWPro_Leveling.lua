-------------------------------
--      WoWPro_Leveling      --
-------------------------------

WoWPro.Leveling = WoWPro:NewModule("Leveling")
local myUFG = UnitFactionGroup("player")

-- Called before all addons have loaded, but after saved variables have loaded. --
function WoWPro.Leveling:OnInitialize()
end

-- Called when the module is enabled, and on log-in and /reload, after all addons have loaded. --
function WoWPro.Leveling:OnEnable()
	WoWPro:dbp("|cff33ff33Enabled|r: Leveling Module")
	
	-- Leveling Tag Setup --
	WoWPro:RegisterTags({"QID", "questtext", "prereq", "noncombat", "leadin"})
	
	-- Event Registration --
	WoWPro.Leveling.Events = {"QUEST_LOG_UPDATE", "QUEST_COMPLETE", "QUEST_QUERY_COMPLETE", 
		"ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "MINIMAP_ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA", 
		"UI_INFO_MESSAGE", "CHAT_MSG_SYSTEM", "CHAT_MSG_LOOT", "PLAYER_LEVEL_UP", "TRAINER_UPDATE"
	}
	WoWPro:RegisterEvents(WoWPro.Leveling.Events)
	
	--Loading Frames--
	if not WoWPro.Leveling.FramesLoaded then --First time the addon has been enabled since UI Load
		WoWPro.Leveling:CreateConfig()
		WoWPro.Leveling.CreateSpellFrame()
		WoWPro.Leveling.CreateSpellListFrame()
		WoWPro.Leveling.FramesLoaded = true
	end
	
	-- Creating empty user settings if none exist --
	WoWPro_LevelingDB = WoWPro_LevelingDB or {}
	WoWPro_LevelingDB.guide = WoWPro_LevelingDB.guide or {} 
	WoWPro_LevelingDB.completedQIDs = WoWPro_LevelingDB.completedQIDs or {}
	WoWPro_LevelingDB.skippedQIDs = WoWPro_LevelingDB.skippedQIDs or {}
	
	-- Loading Initial Guide --
	local locClass, engClass = UnitClass("player")
	local locRace, engRace = UnitRace("player")
	-- New Level 1 Character --
	if UnitLevel("player") == 1 and UnitXP("player") == 0 then
		local startguides = {
			Orc = "JiyDur0105", 
			Troll = "BitDur0105", 
			Scourge = nil,
			Tauren = nil,
			BloodElf = "SnoEve0112",
			Goblin = "MalKez0105", 
			Draenei = "SnoAzu0112",
			NightElf = nil,
			Dwarf = nil,
			Gnome = "GylGno0105",
			Human = "KurElw0111",
			Worgen = "RpoGil0105",
		}
		WoWPro:LoadGuide(startguides[engRace])
	-- New Death Knight --
	elseif UnitLevel("player") == 55 and UnitXP("player") < 1000 and engClass == "DEATHKNIGHT" then
		WoWPro:LoadGuide("JamSca5558")
	-- No current guide, but a guide was stored for later use --
	elseif WoWProDB.char.lastlevelingguide and not WoWProDB.char.currentguide then
		WoWPro:LoadGuide(WoWProDB.char.lastlevelingguide)
	end
	
	WoWPro.Leveling.FirstMapCall = true
	
	-- Server query for completed quests --
	QueryQuestsCompleted()
end

-- Called when the module is disabled --
function WoWPro.Leveling:OnDisable()
	-- Unregistering Leveling Module Events --
	WoWPro:UnregisterEvents(WoWPro.Leveling.Events)
	
	--[[ If the current guide is a leveling guide, removes the map point, stores the guide's ID to be resumed later, 
	sets the current guide to nil, and loads the nil guide. ]]
	if WoWPro.Guides[WoWProDB.char.currentguide].guidetype == "Leveling" then
		WoWPro:RemoveMapPoint()
		WoWProDB.char.lastlevelingguide = WoWProDB.char.currentguide
		WoWProDB.char.currentguide = nil
		WoWPro:LoadGuide()
	end
end

-- Guide Registration Function --
function WoWPro.Leveling:RegisterGuide(GIDvalue, zonename, authorname, startlevelvalue, 
	endlevelvalue, nextGIDvalue, factionname, sequencevalue)
--[[Purpose: Called by guides to register them to the WoWPro.Guide table. All members
of this table must have a quidetype parameter to let the addon know what module should handle that guide.
]]
	if factionname and factionname ~= myUFG and factionname ~= "Neutral" then return end -- If the guide is not of the correct faction, don't register it
	WoWPro:dbp("Guide Registered: "..GIDvalue)
	WoWPro.Guides[GIDvalue] = {
		guidetype = "Leveling",
		zone = zonename,
		author = authorname,
		startlevel = startlevelvalue,
		endlevel = endlevelvalue,
		sequence = sequencevalue,
		nextGID = nextGIDvalue,
	}
end