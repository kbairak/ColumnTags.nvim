local M = {}
local config = require("columntags.config")
local popup = require("columntags.popup")
local utils = require("columntags.utils")

M.enabled = true

local function init_stack()
	if not vim.t.columntags_stack then
		vim.t.columntags_stack = {}
	end
end

function M.setup(opts)
	config.setup(opts)
end

function M.jump()
	if not M.enabled or utils.is_excluded_window() then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)
		return
	end

	-- Disable foldenable
	local foldenable_before = vim.opt.foldenable
	vim.opt.foldenable = false

	local cursor_pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())

	-- Get only non-floating windows in appearance order
	local current_window, windows = utils.get_non_floating_windows()

	-- List of buffers of shown windows up to the current one
	local shown_buffers = {}
	for i = 1, current_window do
		if vim.api.nvim_win_is_valid(windows[i]) then
			local buf = vim.api.nvim_win_get_buf(windows[i])
			local pos = vim.api.nvim_win_get_cursor(windows[i])
			table.insert(shown_buffers, { buf, pos })
		end
	end

	-- List of all buffers that need to be remembered (stacked + shown)
	init_stack()
	local all_buffers = {}
	vim.list_extend(all_buffers, vim.t.columntags_stack)
	vim.list_extend(all_buffers, shown_buffers)

	-- Split buffers, keep last ones on 'right'
	local left = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - (config.max_columns - 1)))
	local right = vim.list_slice(all_buffers, math.max(1, #all_buffers - (config.max_columns - 2)))

	-- Update stack
	vim.t.columntags_stack = left
	-- Must have as many windows as `#right + 1`
	windows = utils.keep_windows(#right + 1)

	-- Map the buffers of 'right' onto windows
	for i, buf in ipairs(right) do
		if vim.api.nvim_win_is_valid(windows[i]) and vim.api.nvim_buf_is_valid(buf[1]) then
			vim.api.nvim_win_set_buf(windows[i], buf[1])
			vim.api.nvim_win_set_cursor(windows[i], buf[2])
		end
	end

	-- Put the last buffer of 'right' in the rightmost window, focus the rightmost window, restore
	-- cursor position, and send `<C-]>`
	if vim.api.nvim_win_is_valid(windows[#right + 1]) then
		vim.api.nvim_win_set_buf(windows[#right + 1], right[#right][1])
		vim.api.nvim_set_current_win(windows[#right + 1])
		vim.api.nvim_win_set_cursor(windows[#right + 1], cursor_pos)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)
	else
		vim.notify("ColumnTags: Target window is invalid", vim.log.levels.WARN)
	end

	-- Enable foldenable again after jump
	vim.opt.foldenable = foldenable_before

	popup.show(vim.t.columntags_stack)
end

function M.back()
	if not M.enabled or utils.is_excluded_window() then
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
		return
	end

	-- Get only non-floating windows in appearance order
	local current_window, windows = utils.get_non_floating_windows()

	-- If current window is not in the list, do nothing
	if current_window == 0 then
		vim.notify("ColumnTags: Current window is not navigable", vim.log.levels.WARN)
		return
	end

	-- If more than one windows and not leftmost has focus, just move focus left
	if current_window > 1 then
		if vim.api.nvim_win_is_valid(windows[current_window - 1]) then
			vim.api.nvim_set_current_win(windows[current_window - 1])
		end
		return
	end

	-- List of buffers of shown windows
	local shown_buffers = {}
	for i = 1, #windows do
		if vim.api.nvim_win_is_valid(windows[i]) then
			local buf = vim.api.nvim_win_get_buf(windows[i])
			local pos = vim.api.nvim_win_get_cursor(windows[i])
			table.insert(shown_buffers, { buf, pos })
		end
	end

	-- List of all buffers that need to be remembered (stacked + shown)
	init_stack()
	local all_buffers = {}
	vim.list_extend(all_buffers, vim.t.columntags_stack)
	vim.list_extend(all_buffers, shown_buffers)

	-- Drop last buffer
	if #all_buffers > config.max_columns then
		all_buffers = vim.list_slice(all_buffers, 1, #all_buffers - 1)
	end

	-- Update stack (all except last max_columns)
	vim.t.columntags_stack = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - config.max_columns))

	-- Keep last max_columns buffers
	local last_three_buffers = vim.list_slice(all_buffers, math.max(1, #all_buffers - (config.max_columns - 1)))

	windows = utils.keep_windows(#last_three_buffers)

	-- Put each buffer in its proper window
	for i, buf in ipairs(last_three_buffers) do
		if vim.api.nvim_win_is_valid(windows[i]) and vim.api.nvim_buf_is_valid(buf[1]) then
			vim.api.nvim_win_set_buf(windows[i], buf[1])
			vim.api.nvim_win_set_cursor(windows[i], buf[2])
		end
	end

	-- Focus the leftmost window
	if vim.api.nvim_win_is_valid(windows[1]) then
		vim.api.nvim_set_current_win(windows[1])
	end
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

function M.set_max_columns(value)
	-- Validate: must be integer >= 1
	local num_value = tonumber(value)
	if not num_value then
		vim.notify("ColumnTags: max_columns must be a number", vim.log.levels.ERROR)
		return
	end

	if num_value < 1 or math.floor(num_value) ~= num_value then
		vim.notify("ColumnTags: max_columns must be an integer >= 1", vim.log.levels.ERROR)
		return
	end

	-- Update config
	config.max_columns = num_value
	vim.notify(
		string.format("ColumnTags: max_columns set to %d (effective on next jump/back)", num_value),
		vim.log.levels.INFO
	)
end

return M
