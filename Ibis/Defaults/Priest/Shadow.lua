local addonName, addonTable = ...

local Addon = _G[addonName]

local class = "PRIEST"
local spec = SPEC_PRIEST_SHADOW

local trackers = {
	{
		actionName = "Vampiric Touch",
		actionType = "spell",
		track = {
			type = "aura",
			unit = "target",
			buff = false,
		},
		indicators = {
			{
				type = "roundHighlight",
				rgbi = { 180, 178, 206 },
			},
		},
	},
}

for _, tracker in pairs(trackers) do
	tracker.class = { class }
	tracker.spec = spec
	table.insert(Addon.defaultTrackerConfigs, tracker)
end