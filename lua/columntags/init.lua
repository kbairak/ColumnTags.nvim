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

	-- Capture state BEFORE the jump
	local orig_buf = vim.api.nvim_get_current_buf()
	local orig_pos = vim.api.nvim_win_get_cursor(0)

	-- Get only non-floating windows in appearance order
	local current_window, windows = utils.get_non_floating_windows()

	-- List of buffers of shown windows up to the current one
	local shown_buffers = {}
	for i = 1, current_window do
		if vim.api.nvim_win_is_valid(windows[i]) then
			local buf = vim.api.nvim_win_get_buf(windows[i])
			-- Save the complete view state (scroll position, folds, cursor)
			local view = vim.api.nvim_win_call(windows[i], vim.fn.winsaveview)
			table.insert(shown_buffers, { buf, view })
		end
	end

	-- Set up a one-time autocmd to detect when jump completes
	local augroup = vim.api.nvim_create_augroup("ColumnTagsJump", { clear = true })
	local triggered = false

	local function handle_jump_complete()
		if triggered then
			return
		end
		triggered = true

		-- Clean up autocmd
		vim.api.nvim_del_augroup_by_id(augroup)

		-- Verify jump succeeded (different buffer OR different position)
		local new_buf = vim.api.nvim_get_current_buf()
		local new_pos = vim.api.nvim_win_get_cursor(0)

		if orig_buf == new_buf and orig_pos[1] == new_pos[1] and orig_pos[2] == new_pos[2] then
			return
		end

		-- Jump succeeded! Current window has the jump destination
		-- Calculate column layout
		init_stack()
		local all_buffers = {}
		vim.list_extend(all_buffers, vim.t.columntags_stack)
		vim.list_extend(all_buffers, shown_buffers)

		-- Split buffers: left for stack, right for visible columns
		local left = vim.list_slice(all_buffers, 1, math.max(0, #all_buffers - (config.max_columns - 1)))
		local right = vim.list_slice(all_buffers, math.max(1, #all_buffers - (config.max_columns - 2)))

		-- Update stack
		vim.t.columntags_stack = left

		-- Delete all other non-floating windows
		local jump_window = vim.api.nvim_get_current_win()
		local _, all_windows = utils.get_non_floating_windows()
		for _, win in ipairs(all_windows) do
			if win ~= jump_window and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, false)
			end
		end

		-- Create vsplits to build columns to the left
		-- We need #right columns to the left of the jump window
		for _ = 1, #right do
			vim.cmd("leftabove vsplit")
		end

		-- Get new window list (should be in left-to-right order)
		_, windows = utils.get_non_floating_windows()

		-- Populate the left windows with column buffers
		for i, buf in ipairs(right) do
			if vim.api.nvim_win_is_valid(windows[i]) and vim.api.nvim_buf_is_valid(buf[1]) then
				vim.api.nvim_win_set_buf(windows[i], buf[1])
				-- Restore the complete view state (scroll position, folds, cursor)
				vim.api.nvim_win_call(windows[i], function()
					vim.fn.winrestview(buf[2])
				end)
			end
		end

		-- Focus the rightmost window (which already has the jump result)
		if #windows > 0 and vim.api.nvim_win_is_valid(windows[#windows]) then
			vim.api.nvim_set_current_win(windows[#windows])
		end

		-- Show popup
		popup.show(vim.t.columntags_stack)
	end

	-- Set up autocmds to detect jump completion (BufEnter or CursorMoved)
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved" }, {
		group = augroup,
		once = true,
		callback = handle_jump_complete,
	})

	-- Fallback timeout in case autocmd doesn't fire
	vim.defer_fn(function()
		handle_jump_complete()
	end, config.fallback_timeout)

	-- Do the jump in-place in the current window
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)
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
			-- Save the complete view state (scroll position, folds, cursor)
			local view = vim.api.nvim_win_call(windows[i], vim.fn.winsaveview)
			table.insert(shown_buffers, { buf, view })
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
			-- Restore the complete view state (scroll position, folds, cursor)
			vim.api.nvim_win_call(windows[i], function()
				vim.fn.winrestview(buf[2])
			end)
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

function M.legacy_jump()
	-- Just do a standard tag jump without column management
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-]>", true, false, true), "n", false)
end

function M.legacy_back()
	-- Just do a standard tag pop without column management
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
end

return M
