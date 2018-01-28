local addonName, addonTable = ...

local Addon = _G[addonName]

local class = "PRIEST"

local trackers = {
	{
		actionName = "Shadow Word: Pain",
		actionType = "spell",
		track = {
			type = "aura",
			unit = "target",
			buff = false,
		},
		indicators = {
			{
				type = "roundHighlight",
				rgbi = { 232, 156, 6 },
			},
		},
	},
}

for _, tracker in pairs(trackers) do
	tracker.class = { class }
	table.insert(Addon.defaultTrackerConfigs, tracker)
end