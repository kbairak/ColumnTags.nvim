-- Load guard
if vim.g.columntags_loaded then
	return
end
vim.g.columntags_loaded = 1

-- Initialize with defaults if not already configured
local columntags = require("columntags")
local config = require("columntags.config")
if not config.excluded_filetypes then
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
local subcommands = {
	enable = function()
		require("columntags").enable()
	end,
	disable = function()
		require("columntags").disable()
	end,
	toggle = function()
		require("columntags").toggle()
	end,
	max_columns = function(args)
		local value = args[2]
		if not value then
			vim.notify("ColumnTags: max_columns requires a value", vim.log.levels.ERROR)
			return
		end
		require("columntags").set_max_columns(value)
	end,
}

vim.api.nvim_create_user_command("ColumnTags", function(opts)
	local subcommand = opts.fargs[1]

	if not subcommand then
		vim.notify(
			string.format("ColumnTags: No subcommand provided. Available: %s", table.concat(vim.tbl_keys(subcommands), ", ")),
			vim.log.levels.ERROR
		)
		return
	end

	local handler = subcommands[subcommand]
	if handler then
		handler(opts.fargs)
	else
		vim.notify(
			string.format("ColumnTags: Unknown subcommand '%s'. Available: %s", subcommand, table.concat(vim.tbl_keys(subcommands), ", ")),
			vim.log.levels.ERROR
		)
	end
end, {
	nargs = "*",
	complete = function()
		return vim.tbl_keys(subcommands)
	end,
	desc = "ColumnTags plugin commands",
})
