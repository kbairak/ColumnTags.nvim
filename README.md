# ColumnTags.nvim

A Miller Columns navigation plugin for Neovim that reimagines definition jumping with a visual column-based interface inspired by macOS Finder.

<https://github.com/user-attachments/assets/fb31eb00-4a83-4b12-9fa5-958951aa4343>

## Overview

Instead of replacing your current buffer when jumping to definitions, `columntags` creates vertical column splits that show your navigation path through the codebase. Navigate forward with `<C-]>` and backward with `<C-t>` while maintaining context of where you've been.

### Features

- **Visual Navigation Path**: See up to 3 columns showing your journey through code definitions
- **Seamless Integration**: Works with LSP, ctags, and any other definition provider (uses native `<C-]>`)
- **Sliding Window**: Older columns are hidden but preserved in a stack as you navigate deeper
- **Tab-Local State**: Each tab maintains independent navigation state
- **Zero Configuration**: Works out of the box with sensible defaults

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'kbairak/columntags.nvim',
  config = function()
    require('columntags').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'kbairak/columntags.nvim',
  config = function()
    require('columntags').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'kbairak/columntags.nvim'

" In your init.lua or init.vim:
lua require('columntags').setup()
```

## Usage

The plugin overrides the default tag jumping behavior with column-based navigation:

| Key     | Action                                    |
|---------|-------------------------------------------|
| `<C-]>` | Jump to definition in new column          |
| `<C-t>` | Navigate back (move focus or restore col) |
| `<C-,>` | Toggle ColumnTags mode                    |

### Navigation Behavior

**Forward Navigation (`<C-]>`):**

- From rightmost column: Creates new column to the right
- When max columns reached: Hides leftmost column (saved to stack)
- From middle column: Closes all columns to the right, creates new column

**Backward Navigation (`<C-t>`):**

- When not on leftmost column: Moves focus one column left
- When on leftmost column: Restores hidden column from stack
- Maintains max column limit when restoring

### Commands

| Command                     | Description                              |
|-----------------------------|------------------------------------------|
| `:ColumnTags enable`        | Enable ColumnTags navigation             |
| `:ColumnTags disable`       | Disable ColumnTags navigation            |
| `:ColumnTags toggle`        | Toggle ColumnTags on/off                 |
| `:ColumnTags max_columns N` | Set max columns to N (takes effect next) |

When disabled, `<C-]>` and `<C-t>` fall back to Neovim's default tag behavior.

## Configuration

The plugin works out of the box with sensible defaults. Call `setup()` to customize window exclusions:

```lua
require('columntags').setup({
  -- Configuration options
})
```

### Options

#### Max Columns

Control the maximum number of visible columns:

- `max_columns` - Maximum number of columns to display (default: `3`)

```lua
require('columntags').setup({
  max_columns = 5,  -- Show up to 5 columns instead of 3
})
```

You can also change this value at runtime:

```vim
:ColumnTags max_columns 4
```

The new value takes effect on the next `jump()` or `back()` action.

#### Popup Timeout

Control how long the stack depth indicator popup is displayed:

- `popup_timeout` - Duration in milliseconds to show the popup (default: `2000`)

```lua
require('columntags').setup({
  popup_timeout = 3000,  -- Show popup for 3 seconds instead of 2
})
```

The popup appears when you navigate and shows the hidden stack depth. Set a higher value if you want more time to read it, or a lower value for a quicker dismiss.

#### Keymaps

Control which keymaps are registered by the plugin. By default, three keymaps are registered, but you can customize, disable, or completely remove all default keymaps.

**Default Keymaps:**

- `jump` - `<C-]>` - Jump to definition
- `back` - `<C-t>` - Navigate back
- `toggle` - `<C-,>` - Toggle plugin on/off

**Disable all default keymaps:**

```lua
require('columntags').setup({
  keymaps = false,
})
```

**Customize specific keymaps:**

```lua
require('columntags').setup({
  keymaps = {
    jump = "<leader>gd",
    back = "<leader>gb",
    -- toggle keeps default <C-,>
  },
})
```

**Disable individual keymaps:**

```lua
require('columntags').setup({
  keymaps = {
    toggle = false,  -- Don't map toggle
    -- jump and back keep defaults <C-]> and <C-t>
  },
})
```

**Set your own keymaps manually when defaults are disabled:**

```lua
require('columntags').setup({
  keymaps = false,
})

-- Define your own keymaps
vim.keymap.set("n", "<leader>]", function()
  require("columntags").jump()
end, { silent = true, desc = "Column Tags: Jump" })

vim.keymap.set("n", "<leader>[", function()
  require("columntags").back()
end, { silent = true, desc = "Column Tags: Back" })
```

#### Excluded Filetypes and Buftypes

The plugin excludes certain window types from column navigation (file explorers, terminals, help windows, etc.). You can customize these exclusions using **replace mode** or **extend mode**.

**Replace Mode** - Provide your own complete list:

- `excluded_filetypes` - Replace default excluded filetypes entirely
- `excluded_buftypes` - Replace default excluded buftypes entirely

**Extend Mode** - Add to the defaults:

- `add_excluded_filetypes` - Add filetypes to default exclusions
- `add_excluded_buftypes` - Add buftypes to default exclusions

**Default Excluded Filetypes:**
`neo-tree`, `NvimTree`, `nerdtree`, `oil`, `fugitive`, `fugitiveblame`, `gitcommit`, `gitrebase`, `toggleterm`, `qf`, `help`, `man`, `Trouble`, `trouble`, `aerial`, `Outline`, `undotree`, `diff`, `DiffviewFiles`, `TelescopePrompt`, `lazy`, `mason`, `lspinfo`, `dashboard`, `alpha`, `starter`

**Default Excluded Buftypes:**
`terminal`, `nofile`, `quickfix`, `prompt`, `help`

### Configuration Examples

**Replace mode** - Use only your specified exclusions:

```lua
require('columntags').setup({
  excluded_filetypes = { "neo-tree", "oil" },
  -- Only neo-tree and oil are excluded, all defaults ignored
})
```

**Extend mode** - Add to the defaults:

```lua
require('columntags').setup({
  add_excluded_filetypes = { "my-custom-explorer", "my-special-buffer" },
  -- All defaults PLUS your custom types
})
```

**Configure both lists**:

```lua
require('columntags').setup({
  add_excluded_filetypes = { "custom-type" },
  excluded_buftypes = { "terminal" },  -- Replace: only terminal excluded
})
```

**Empty exclusions** - Navigate through all windows:

```lua
require('columntags').setup({
  excluded_filetypes = {},
  excluded_buftypes = {},
})
```

### Fallback Behavior

When you invoke `<C-]>` or `<C-t>` from an excluded window (like neo-tree or a quickfix list), the plugin automatically falls back to Neovim's default tag navigation behavior instead of using column navigation. This ensures excluded windows work as expected without interfering with the plugin's navigation system.

## How It Works

1. **Native Integration**: Sends actual `<C-]>` keystroke to Neovim, preserving all definition providers (LSP, ctags, etc.)
2. **Automatic Detection**: Detects successful jumps and creates column splits automatically
3. **Tab-Local State**: Each tab maintains its own hidden stack and column configuration
4. **Smart Window Management**: Neovim automatically restores cursor position and scroll state for each buffer

## Compatibility

- **Neovim**: 0.8.0 or higher (uses tab-scoped variables and modern APIs)
- **LSP**: Full support for all LSP definition providers
- **ctags**: Works with traditional ctags
- **Multiple Definitions**: Automatically shows Neovim's picker when multiple definitions exist

## Examples

### Basic Usage

```
Start: [main.lua]
Press <C-]> on function call
Result: [main.lua] [function.lua]

Press <C-]> again
Result: [main.lua] [function.lua] [utils.lua]

Press <C-]> once more (exceeds max_columns=3)
Result: [function.lua] [utils.lua] [helpers.lua]
       (main.lua hidden in stack)

Press <C-t> repeatedly
Result: Focus moves left, then columns slide left as stack restores
```

### Branching Navigation

```
State: [a.lua] [b.lua] [c.lua]
Focus on b.lua, press <C-]>
Result: [a.lua] [b.lua] [new.lua]
       (c.lua closed, hidden stack cleared)
```

## Future Enhancements

- [x] If no tag under cursor, do nothing (jump is attempted first, window layout only changes if jump succeeds)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details
