local addonName, addonTable = ...

local Addon = _G[addonName]

local class = "WARLOCK"
local spec = SPEC_WARLOCK_DESTRUCTION

local trackers = {
	{
		actionName = "Immolate",
		actionType = "spell",
		track = {
			type = "aura",
			unit = "target",
			buff = false,
		},
		indicators = {
			{
				type = "roundHighlight",
				rgbi = { 255, 207, 82 },
			},
		},
	},

	{
		actionName = "Conflagrate",
		actionType = "spell",
		talent = { { 1, 1 } }, -- Level 15: Backdraft
		track = {
			type = "aura",
			unit = "player",
			name = "Backdraft",
			buff = true,
			stacks = 2,
		},
		indicators = {
			{
				type = "roundHighlight",
				rgbi = { 255, 207, 124 },
			},
		},
	},

	{
		actionName = "Life Tap",
		actionType = "spell",
		talent = { { 2, 3 } }, -- Level 30: Empowered Life Tap
		track = {
			type = "aura",
			unit = "player",
			name = "Empowered Life Tap",
			buff = true,
		},
		indicators = {
			{
				type = "roundHighlight",
				rgbi = { 228, 110, 160 },
			},
		},
	},
}

for _, tracker in pairs(trackers) do
	tracker.class = { class }
	tracker.spec = spec
	table.insert(Addon.defaultTrackerConfigs, tracker)
end