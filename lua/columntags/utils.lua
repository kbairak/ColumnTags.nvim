local M = {}
local config = require("columntags.config")

-- Check if a window should be excluded from navigation
-- @param win: window ID (optional, defaults to current window)
-- @return boolean: true if window should be excluded
function M.is_excluded_window(win)
	win = win or vim.fn.win_getid()

	-- Return true if window is invalid
	if not vim.api.nvim_win_is_valid(win) then
		return true
	end

	local win_config = vim.api.nvim_win_get_config(win)
	local buf = vim.api.nvim_win_get_buf(win)
	local filetype = vim.bo[buf].filetype
	local buftype = vim.bo[buf].buftype
	return win_config.relative ~= ""
		or config.excluded_filetypes[filetype]
		or config.excluded_buftypes[buftype]
end

-- Get all non-floating, non-excluded windows
-- @return current_window: index of current window in the list (0 if not found)
-- @return windows: list of window IDs
function M.get_non_floating_windows()
	local current_window = 0
	local windows = {}

	for i = 1, vim.fn.winnr("$") do
		local win = vim.fn.win_getid(i)
		if not M.is_excluded_window(win) then
			table.insert(windows, win)
			if win == vim.api.nvim_get_current_win() then
				current_window = #windows
			end
		end
	end

	return current_window, windows
end

-- Adjust window count to match the target count
-- @param count: target number of windows
-- @return windows: list of window IDs after adjustment
function M.keep_windows(count)
	local _, windows = M.get_non_floating_windows()
	local window_count = #windows

	while window_count < count do
		vim.cmd("vsplit")
		window_count = window_count + 1
	end

	while window_count > count do
		if vim.api.nvim_win_is_valid(windows[window_count]) then
			vim.api.nvim_win_close(windows[window_count], false)
		end
		window_count = window_count - 1
	end

	local _, result = M.get_non_floating_windows()
	return result
end

return M