local M = { excluded_filetypes = nil, excluded_buftypes = nil }

-- Default configuration
local default_config = {
	excluded_filetypes = {
		-- File explorers
		"neo-tree",
		"NvimTree",
		"nerdtree",
		"oil",
		-- Git
		"fugitive",
		"fugitiveblame",
		"gitcommit",
		"gitrebase",
		-- Terminals
		"toggleterm",
		-- Special windows
		"qf",
		"help",
		"man",
		"Trouble",
		"trouble",
		"aerial",
		"Outline",
		"undotree",
		"diff",
		"DiffviewFiles",
		"TelescopePrompt",
		"lazy",
		"mason",
		"lspinfo",
		"dashboard",
		"alpha",
		"starter",
	},
	excluded_buftypes = {
		"terminal",
		"nofile",
		"quickfix",
		"prompt",
		"help",
	},
}

-- Setup configuration with user options
-- @param opts: user configuration options
--   - excluded_filetypes: replace default excluded filetypes
--   - add_excluded_filetypes: extend default excluded filetypes
--   - excluded_buftypes: replace default excluded buftypes
--   - add_excluded_buftypes: extend default excluded buftypes
function M.setup(user_opts)
	user_opts = user_opts or {}

	-- Start with defaults
	local opts = {
		excluded_filetypes = vim.deepcopy(default_config.excluded_filetypes),
		excluded_buftypes = vim.deepcopy(default_config.excluded_buftypes),
	}

	-- Handle excluded_filetypes: replace or extend
	if user_opts.excluded_filetypes then
		opts.excluded_filetypes = user_opts.excluded_filetypes
	elseif user_opts.add_excluded_filetypes then
		vim.list_extend(opts.excluded_filetypes, user_opts.add_excluded_filetypes)
	end

	-- Handle excluded_buftypes: replace or extend
	if user_opts.excluded_buftypes then
		opts.excluded_buftypes = user_opts.excluded_buftypes
	elseif user_opts.add_excluded_buftypes then
		vim.list_extend(opts.excluded_buftypes, user_opts.add_excluded_buftypes)
	end

	-- Convert lists to lookup tables for efficient checking
	M.excluded_filetypes = {}
	for _, ft in ipairs(opts.excluded_filetypes) do
		M.excluded_filetypes[ft] = true
	end

	M.excluded_buftypes = {}
	for _, bt in ipairs(opts.excluded_buftypes) do
		M.excluded_buftypes[bt] = true
	end
end

return M
