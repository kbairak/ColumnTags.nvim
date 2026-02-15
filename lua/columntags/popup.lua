local M = {}

local state = {
	buf = nil,
	win = nil,
	timer = nil,
}

local function hide()
	if state.timer then
		state.timer:stop()
		state.timer = nil
	end

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win = nil

	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_delete(state.buf, { force = true })
	end
	state.buf = nil
end

-- Show stack popup with the given stack entries
-- @param stack: array of {bufnr, {line, col}} entries
function M.show(stack)
	stack = stack or {}
	local lines = { "ColumnTags stack:" }

	for _, buf in ipairs(stack) do
		local bufname = vim.api.nvim_buf_get_name(buf[1])
		local line_num = buf[2][1]

		-- Get relative path if file is descendant of cwd
		local display_name
		if bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
			local relative = vim.fn.fnamemodify(bufname, ":.")
			-- Check if it's actually relative (doesn't start with /)
			if not vim.startswith(relative, "/") then
				display_name = relative
			else
				display_name = vim.fn.fnamemodify(bufname, ":t")
			end
		else
			display_name = vim.fn.fnamemodify(bufname, ":t")
		end

		local line_text = string.format("%s:%d", display_name, line_num)
		table.insert(lines, line_text)
	end

	-- If stack is empty, hide popup and return
	if #lines == 1 then
		if state.buf then
			hide()
		end
		return
	end

	if state.timer then
		state.timer:stop()
		state.timer = nil
	end

	-- Define maximum width
	local max_width = 50

	-- Truncate lines that exceed max_width and add line numbers
	local display_lines = {}
	for i, line in ipairs(lines) do
		local formatted_line
		if i > 1 then
			-- Add line number prefix for stack entries (not the header)
			formatted_line = string.format("%d. %s", i - 1, line)
		else
			formatted_line = line
		end

		if #formatted_line > max_width then
			-- Keep the end, replace start with ellipsis
			local truncated = "…" .. string.sub(formatted_line, -(max_width - 1))
			table.insert(display_lines, truncated)
		else
			table.insert(display_lines, formatted_line)
		end
	end

	-- Calculate width based on truncated content
	local width = 20
	for _, line in ipairs(display_lines) do
		width = math.max(width, #line + 4) -- +2 for padding
	end
	width = math.min(width, max_width + 4) -- Cap at max_width + padding

	local win_config = {
		relative = "editor",
		width = width,
		height = #display_lines,
		row = 1,
		col = 1,
		style = "minimal",
		border = "rounded",
		focusable = false,
		zindex = 50,
	}

	if state.buf then
		-- Check if window is still valid before trying to configure it
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_set_config(state.win, win_config)
		else
			-- Window was closed externally, recreate it
			state.buf = nil
		end
	end

	if not state.buf then
		state.buf = vim.api.nvim_create_buf(false, true)
		state.win = vim.api.nvim_open_win(state.buf, false, win_config)
	end

	if vim.api.nvim_buf_is_valid(state.buf) then
		vim.bo[state.buf].modifiable = true
		vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, display_lines)
		vim.bo[state.buf].modifiable = false
	end

	state.timer = vim.defer_fn(hide, 2000)
end

return M

