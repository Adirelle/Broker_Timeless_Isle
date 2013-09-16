--[[
Broker_VolumeProfiles - Switchables volume profiles.
Copyright (C) 2013 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

local addonName, private = ...

local addon = CreateFrame("Frame")
local db
local dataobj

local quests = {
	-- Weekly/daily repeatable quests
	[33334] = "Strong Enough To Survive",
	[33338] = "Empowering the Hourglass",
	[33374] = "Path of the Mistwalker",
	[33211] = "A Timeless Question",
	-- [33137] = "The Celestial Tournament",
	-- One-time chests
	[33210] = "Blazing Chest",
	[33203] = "Skull-Covered Chest",
	[33209] = "Smouldering Chest (Firewalker Ruins)",
	[33208] = "Smouldering Chest (Shrine of the Black Flame)",
	-- Weekly-lootable chests
	[32956] = "Blackguard's Jetsam",
	[32957] = "Sunken Hozen Treasure",
	-- [] = "Gleaming Crane Statue",
	[32970] = "Gleaming Treasure Satchel",
	[32969] = "Gleaming Treasure Chest",
	[32968] = "Rope-Bound Treasure Chest",
}

local actuallyQuests = {
	[33334] = true,
	[33338] = true,
	[33374] = true,
	[33211] = true,
}

local oneTimeQuest = {
	[33210] = true,
	[33203] = true,
	[33209] = true,
	[33208] = true,
}

local locations = {
	[33210] = { 47, 27 }, -- Blazing Chest
	[33203] = { 46, 32 }, -- Skull-Covered Chest
	[33209] = { 54, 78 }, -- Smouldering Chest (Firewalker Ruins)
	[33208] = { 69, 33 }, -- Smouldering Chest (Shrine of the Black Flame)
	[32956] = { 22, 59 }, -- Blackguard's Jetsam
	[32957] = { 40, 93 }, -- Sunken Hozen Treasure
--	[] = { 58, 60 }, -- Gleaming Crane Statue
	[32970] = { 70, 80 }, -- Gleaming Treasure Satchel
	[32969] = { 46, 69 }, -- Gleaming Treasure Chest
	[32968] = { 54, 47 }, -- Rope-Bound Treasure Chest
}

local DEFAULTS = {
	profile = {
		minimapIcon = { hide = false }
	}
}

local todo, done, inProgress = {}, {}, {}
function addon:Update()
	wipe(todo)
	wipe(done)
	wipe(inProgress)
	for id in pairs(quests) do
		local index = GetQuestLogIndexByID(id)
		if index and index > 0 then
			inProgress[id] = true
			quests[id] = GetQuestLogTitle(index) or quests[id]
		end
		if IsQuestFlaggedCompleted(id) then
			if not oneTimeQuest[id] then
				tinsert(done, id)
			end
		else
			tinsert(todo, id)
		end
	end
	local completed, total = #done, (#done+#todo)
	dataobj.text = format("%d/%d", completed, total)
end

local function GetQuestTitle(id, done)
	local title = quests[id]
	if not done and actuallyQuests[id] then
		local icon
		if inProgress[id] then
			icon = 'Interface\\GossipFrame\\IncompleteQuestIcon'
		elseif oneTimeQuest[id] then
			icon = 'Interface\\GossipFrame\\AvailableQuestIcon'
		else
			icon = 'Interface\\GossipFrame\\DailyQuestIcon'
		end
		title = format("\124T%s:0:0:0:0:64:64:5:59:5:59\124t %s", icon, title)
	end
	if oneTimeQuest[id] then
		title = title .. ' (once)'
	end
	return title
end

function addon:OnTooltipShow(tooltip)
	tooltip:AddLine('Timeless Isle', 1, 1, 1)
	if #todo > 0 then
		tooltip:AddLine("To do:", 1, 1, 0)
		for i, id in ipairs(todo) do
			tooltip:AddLine(GetQuestTitle(id, false))
		end
	end
	if #done > 0 then
		tooltip:AddLine("Done:", 0, 1, 0)
		for i, id in ipairs(done) do
			tooltip:AddLine(GetQuestTitle(id, true))
		end
	end
	tooltip:Show()
end

function addon:QUEST_QUERY_COMPLETE()
	return self:Update()
end

function addon:ADDON_LOADED(_, name)
	if name ~= addonName then return end
	self:UnregisterEvent('ADDON_LOADED')

	db = LibStub('AceDB-3.0'):New(addonName..'DB', DEFAULTS, true)

	dataobj = LibStub('LibDataBroker-1.1'):NewDataObject(addonName, {
		type = "data source",
		label = "Timeless Isle",
		icon = "Interface/Icons/timelesscoin",
		--OnClick = function(...) return self:OnClick(...) end,
		OnTooltipShow = function(...) return self:OnTooltipShow(...) end,
	})
	
	LibStub('LibDBIcon-1.0'):Register(addonName, dataobj, db.profile.minimapIcon)

	self:RegisterEvent('QUEST_QUERY_COMPLETE')

	self:Update()
end

addon:SetScript('OnEvent', function(self, event, ...) return self[event](self, event, ...) end)
addon:RegisterEvent('ADDON_LOADED')
