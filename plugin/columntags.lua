-- Load guard
if vim.g.columntags_loaded then
	return
end
vim.g.columntags_loaded = 1

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

-- Preserve default behavior with g prefix
vim.keymap.set("n", "g<C-]>", "<C-]>", {
	silent = true,
	desc = "Default: Jump to tag",
})

vim.keymap.set("n", "g<C-t>", "<C-t>", {
	silent = true,
	desc = "Default: Jump back in tag stack",
})
