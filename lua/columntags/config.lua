local M = { excluded_filetypes = nil, excluded_buftypes = nil, max_columns = nil, keymaps = nil, popup_timeout = nil, fallback_timeout = nil }

-- Default configuration
local default_config = {
	max_columns = 3,
	popup_timeout = 2000,
	fallback_timeout = 100,
	keymaps = {
		jump = "<C-]>",
		back = "<C-t>",
		legacy_jump = "<C-.>",
		legacy_back = "<C-,>",
	},
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
--   - max_columns: maximum number of columns to show (default: 3)
--   - popup_timeout: timeout in milliseconds for the stack popup (default: 2000)
--   - excluded_filetypes: replace default excluded filetypes
--   - add_excluded_filetypes: extend default excluded filetypes
--   - excluded_buftypes: replace default excluded buftypes
--   - add_excluded_buftypes: extend default excluded buftypes
--   - keymaps: configure keymaps (false to disable all, table to customize/disable individual)
function M.setup(user_opts)
	user_opts = user_opts or {}

	-- Start with defaults
	local opts = {
		max_columns = default_config.max_columns,
		popup_timeout = default_config.popup_timeout,
		fallback_timeout = default_config.fallback_timeout,
		excluded_filetypes = vim.deepcopy(default_config.excluded_filetypes),
		excluded_buftypes = vim.deepcopy(default_config.excluded_buftypes),
		keymaps = vim.deepcopy(default_config.keymaps),
	}

	-- Handle max_columns
	if user_opts.max_columns then
		opts.max_columns = user_opts.max_columns
	end

	-- Handle popup_timeout
	if user_opts.popup_timeout then
		opts.popup_timeout = user_opts.popup_timeout
	end

	-- Handle fallback_timeout
	if user_opts.fallback_timeout then
		opts.fallback_timeout = user_opts.fallback_timeout
	end

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

	-- Handle keymaps
	if user_opts.keymaps == false then
		-- Disable all keymaps
		opts.keymaps = false
	elseif type(user_opts.keymaps) == "table" then
		-- Merge user keymaps with defaults
		-- This allows partial override and individual disable with false
		for key, value in pairs(user_opts.keymaps) do
			opts.keymaps[key] = value
		end
	end

	-- Store max_columns
	M.max_columns = opts.max_columns

	-- Store popup_timeout
	M.popup_timeout = opts.popup_timeout

	-- Store fallback_timeout
	M.fallback_timeout = opts.fallback_timeout

	-- Convert lists to lookup tables for efficient checking
	M.excluded_filetypes = {}
	for _, ft in ipairs(opts.excluded_filetypes) do
		M.excluded_filetypes[ft] = true
	end

	M.excluded_buftypes = {}
	for _, bt in ipairs(opts.excluded_buftypes) do
		M.excluded_buftypes[bt] = true
	end

	-- Store keymaps
	M.keymaps = opts.keymaps
end

return M
