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

	-- Update stack (all except last 2)
	vim.t.columntags_stack = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - 2))

	-- Keep last two buffers
	local last_two_buffers = vim.list_slice(all_buffers, math.max(1, #all_buffers - 1))

	-- Must have as many windows as `#last_two_buffers + 1`
	windows = utils.keep_windows(#last_two_buffers + 1)

	-- If size of last_two_buffers is 1, put the buffer in the both windows
	if #last_two_buffers == 1 then
		if vim.api.nvim_win_is_valid(windows[1]) and vim.api.nvim_buf_is_valid(last_two_buffers[1][1]) then
			vim.api.nvim_win_set_buf(windows[1], last_two_buffers[1][1])
			vim.api.nvim_win_set_cursor(windows[1], last_two_buffers[1][2])
		end
		if vim.api.nvim_win_is_valid(windows[2]) and vim.api.nvim_buf_is_valid(last_two_buffers[1][1]) then
			vim.api.nvim_win_set_buf(windows[2], last_two_buffers[1][1])
			vim.api.nvim_win_set_cursor(windows[2], last_two_buffers[1][2])
		end
	-- Else, if size of last_two_buffers is 2, put the second-to-last buffer in the first window and
	-- the last buffer in the second and third window
	else
		if vim.api.nvim_win_is_valid(windows[1]) and vim.api.nvim_buf_is_valid(last_two_buffers[1][1]) then
			vim.api.nvim_win_set_buf(windows[1], last_two_buffers[1][1])
			vim.api.nvim_win_set_cursor(windows[1], last_two_buffers[1][2])
		end
		if vim.api.nvim_win_is_valid(windows[2]) and vim.api.nvim_buf_is_valid(last_two_buffers[2][1]) then
			vim.api.nvim_win_set_buf(windows[2], last_two_buffers[2][1])
			vim.api.nvim_win_set_cursor(windows[2], last_two_buffers[2][2])
		end
		if vim.api.nvim_win_is_valid(windows[3]) and vim.api.nvim_buf_is_valid(last_two_buffers[2][1]) then
			vim.api.nvim_win_set_buf(windows[3], last_two_buffers[2][1])
		end
	end

	-- Focus the rightmost window, restore cursor position, and send `<C-]>`
	local target_win = windows[#last_two_buffers + 1]
	if vim.api.nvim_win_is_valid(target_win) then
		vim.api.nvim_set_current_win(target_win)
		vim.api.nvim_win_set_cursor(target_win, cursor_pos)
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
	if #all_buffers > 3 then
		all_buffers = vim.list_slice(all_buffers, 1, #all_buffers - 1)
	end

	-- Update stack (all except last 3)
	vim.t.columntags_stack = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - 3))

	-- Keep last three buffers
	local last_three_buffers = vim.list_slice(all_buffers, math.max(1, #all_buffers - 2))

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

return M
