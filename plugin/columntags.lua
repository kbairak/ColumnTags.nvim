-- Load guard
if vim.g.columntags_loaded then
	return
end
vim.g.columntags_loaded = 1

-- Initialize with defaults if not already configured
local columntags = require("columntags")
if not columntags.config then
	columntags.setup()
end

-- Default keymap setup
vim.keymap.set("n", "<C-]>", function()
	require("columntags").jump()
end, {
	silent = true,
	desc = "Column Tags: Jump to definition",
})

vim.keymap.set("n", "<C-t>", function()
	require("columntags").back()
end, {
	silent = true,
	desc = "Column Tags: Navigate back",
})

vim.keymap.set("n", "<C-,>", function()
	require("columntags").toggle()
end, {
	silent = true,
	desc = "Column Tags: Toggle plugin",
})

-- Commands
vim.api.nvim_create_user_command("ColumnTagsEnable", function()
	require("columntags").enable()
end, {
	desc = "Enable ColumnTags plugin",
})

vim.api.nvim_create_user_command("ColumnTagsDisable", function()
	require("columntags").disable()
end, {
	desc = "Disable ColumnTags plugin",
})

vim.api.nvim_create_user_command("ColumnTagsToggle", function()
	require("columntags").toggle()
end, {
	desc = "Toggle ColumnTags plugin on/off",
})
