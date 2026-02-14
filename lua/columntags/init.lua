local M = {}
local popup = require("columntags.popup")

M.enabled = true
M.config = nil

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

local function init_stack()
	if not vim.t.columntags_stack then
		vim.t.columntags_stack = {}
	end
end

-- Setup function
function M.setup(opts)
	opts = opts or {}

	-- Start with defaults
	local config = {
		excluded_filetypes = vim.deepcopy(default_config.excluded_filetypes),
		excluded_buftypes = vim.deepcopy(default_config.excluded_buftypes),
	}

	-- Handle excluded_filetypes: replace or extend
	if opts.excluded_filetypes then
		config.excluded_filetypes = opts.excluded_filetypes
	elseif opts.add_excluded_filetypes then
		vim.list_extend(config.excluded_filetypes, opts.add_excluded_filetypes)
	end

	-- Handle excluded_buftypes: replace or extend
	if opts.excluded_buftypes then
		config.excluded_buftypes = opts.excluded_buftypes
	elseif opts.add_excluded_buftypes then
		vim.list_extend(config.excluded_buftypes, opts.add_excluded_buftypes)
	end

	-- Convert lists to lookup tables for efficient checking
	local excluded_filetypes_lookup = {}
	for _, ft in ipairs(config.excluded_filetypes) do
		excluded_filetypes_lookup[ft] = true
	end

	local excluded_buftypes_lookup = {}
	for _, bt in ipairs(config.excluded_buftypes) do
		excluded_buftypes_lookup[bt] = true
	end

	M.config = {
		excluded_filetypes = excluded_filetypes_lookup,
		excluded_buftypes = excluded_buftypes_lookup,
	}
end

local function is_excluded_window(win)
	win = win or vim.fn.win_getid()
	local config = vim.api.nvim_win_get_config(win)
	local buf = vim.api.nvim_win_get_buf(win)
	local filetype = vim.bo[buf].filetype
	local buftype = vim.bo[buf].buftype
	return config.relative ~= "" or M.config.excluded_filetypes[filetype] or M.config.excluded_buftypes[buftype]
end

local function get_non_floating_windows()
	-- Initialize config with defaults if not already set
	if not M.config then
		M.setup()
	end

	local current_window = 0
	local windows = {}

	for i = 1, vim.fn.winnr("$") do
		local win = vim.fn.win_getid(i)
		if not is_excluded_window(win) then
			table.insert(windows, win)
			if win == vim.api.nvim_get_current_win() then
				current_window = #windows
			end
		end
	end

	return current_window, windows
end

local function keep_windows(count)
	local _, windows = get_non_floating_windows()
	local window_count = #windows
	while window_count < count do
		vim.cmd("vsplit")
		window_count = window_count + 1
	end
	while window_count > count do
		vim.api.nvim_win_close(windows[window_count], false)
		window_count = window_count - 1
	end

	local _, result = get_non_floating_windows()
	return result
end

function M.jump()
	if not M.enabled or is_excluded_window() then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)
		return
	end

	-- Disable foldenable
	local foldenable_before = vim.opt.foldenable
	vim.opt.foldenable = false

	local cursor_pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())

	-- Get only non-floating windows in appearance order
	local current_window, windows = get_non_floating_windows()

	-- List of buffers of shown windows up to the current one
	local shown_buffers = {}
	for i = 1, current_window do
		local buf = vim.api.nvim_win_get_buf(windows[i])
		local pos = vim.api.nvim_win_get_cursor(windows[i])
		table.insert(shown_buffers, { buf, pos })
	end

	-- List of all buffers that need to be remembered (stacked + shown)
	init_stack()
	local all_buffers = {}
	vim.list_extend(all_buffers, vim.t.columntags_stack)
	vim.list_extend(all_buffers, shown_buffers)

	-- Update stack (all except last 2)
	vim.t.columntags_stack = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - 2))

	-- Keep last two buffers
	local last_two_buffers = vim.list_slice(all_buffers, math.max(1, #all_buffers - 1))

	-- Must have as many windows as `#last_two_buffers + 1`
	windows = keep_windows(#last_two_buffers + 1)

	-- If size of last_two_buffers is 1, put the buffer in the both windows
	if #last_two_buffers == 1 then
		vim.api.nvim_win_set_buf(windows[1], last_two_buffers[1][1])
		vim.api.nvim_win_set_cursor(windows[1], last_two_buffers[1][2])
		vim.api.nvim_win_set_buf(windows[2], last_two_buffers[1][1])
		vim.api.nvim_win_set_cursor(windows[2], last_two_buffers[1][2])
	-- Else, if size of last_two_buffers is 2, put the second-to-last buffer in the first window and
	-- the last buffer in the second and third window
	else
		vim.api.nvim_win_set_buf(windows[1], last_two_buffers[1][1])
		vim.api.nvim_win_set_cursor(windows[1], last_two_buffers[1][2])
		vim.api.nvim_win_set_buf(windows[2], last_two_buffers[2][1])
		vim.api.nvim_win_set_cursor(windows[2], last_two_buffers[2][2])
		vim.api.nvim_win_set_buf(windows[3], last_two_buffers[2][1])
	end

	-- Focus the rightmost window, restore cursor position, and send `<C-]>`
	local target_win = windows[#last_two_buffers + 1]
	vim.api.nvim_set_current_win(target_win)
	vim.api.nvim_win_set_cursor(target_win, cursor_pos)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)

	-- Enable foldenable again after jump
	vim.opt.foldenable = foldenable_before

	popup.show(vim.t.columntags_stack)
end

function M.back()
	if not M.enabled or is_excluded_window() then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
		return
	end

	-- Get only non-floating windows in appearance order
	local current_window, windows = get_non_floating_windows()

	-- If more than one windows and not leftmost has focus, just move focus left
	if current_window > 1 then
		vim.api.nvim_set_current_win(windows[current_window - 1])
		return
	end

	-- List of buffers of shown windows
	local shown_buffers = {}
	for i = 1, #windows do
		local buf = vim.api.nvim_win_get_buf(windows[i])
		local pos = vim.api.nvim_win_get_cursor(windows[i])
		table.insert(shown_buffers, { buf, pos })
	end

	-- List of all buffers that need to be remembered (stacked + shown)
	init_stack()
	local all_buffers = {}
	vim.list_extend(all_buffers, vim.t.columntags_stack)
	vim.list_extend(all_buffers, shown_buffers)

	-- Drop last buffer
	if #all_buffers > 3 then
		all_buffers = vim.list_slice(all_buffers, 1, #all_buffers - 1)
	end

	-- Update stack (all except last 3)
	vim.t.columntags_stack = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - 3))

	-- Keep last three buffers
	local last_three_buffers = vim.list_slice(all_buffers, math.max(1, #all_buffers - 2))

	windows = keep_windows(#last_three_buffers)

	-- Put each buffer in its proper window
	for i, buf in ipairs(last_three_buffers) do
		vim.api.nvim_win_set_buf(windows[i], buf[1])
		vim.api.nvim_win_set_cursor(windows[i], buf[2])
	end

	-- Focus the leftmost window
	vim.api.nvim_set_current_win(windows[1])
	popup.show(vim.t.columntags_stack)
end

function M.enable()
	M.enabled = true
	vim.notify("ColumnTags enabled", vim.log.levels.INFO)
end

function M.disable()
	M.enabled = false
	vim.notify("ColumnTags disabled", vim.log.levels.INFO)
end

function M.toggle()
	if M.enabled then
		M.disable()
	else
		M.enable()
	end
end

return M
