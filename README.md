# ColumnTags.nvim

A Miller Columns navigation plugin for Neovim that reimagines definition jumping with a visual column-based interface inspired by macOS Finder.

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
  'yourusername/columntags.nvim',
  config = function()
    require('columntags').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/columntags.nvim',
  config = function()
    require('columntags').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'yourusername/columntags.nvim'

" In your init.lua or init.vim:
lua require('columntags').setup()
```

## Usage

The plugin overrides the default tag jumping behavior with column-based navigation:

| Key       | Action                                    |
|-----------|-------------------------------------------|
| `<C-]>`   | Jump to definition in new column          |
| `<C-t>`   | Navigate back (move focus or restore col) |

### Navigation Behavior

**Forward Navigation (`<C-]>`):**

- From rightmost column: Creates new column to the right
- When max columns reached: Hides leftmost column (saved to stack)
- From middle column: Closes all columns to the right, creates new column

**Backward Navigation (`<C-t>`):**

- When not on leftmost column: Moves focus one column left
- When on leftmost column: Restores hidden column from stack
- Maintains max column limit when restoring

## Configuration

```lua
require('columntags').setup({
  max_columns = 3,     -- Maximum number of visible columns (default: 3)
  keymaps = true,      -- Enable default keymaps (default: true)
  debug = false        -- Enable debug logging (default: false)
})
```

### Options

- **`max_columns`** (number, default: `3`)
  - Maximum number of visible columns before hiding leftmost
  - Recommended range: 2-4 depending on screen width

- **`keymaps`** (boolean, default: `true`)
  - Whether to enable default `<C-]>` and `<C-t>` keymaps
  - Set to `false` if you want to define custom mappings

- **`debug`** (boolean, default: `false`)
  - Enable debug logging to help troubleshoot issues
  - Logs will appear in `:messages` with `[columntags]` prefix

### Custom Keymaps

If you disable default keymaps, you can create your own:

```lua
require('columntags').setup({ keymaps = false })

vim.keymap.set('n', 'gd', function()
  require('columntags').jump()
end, { desc = 'Jump to definition (column)' })

vim.keymap.set('n', 'gb', function()
  require('columntags').back()
end, { desc = 'Navigate back (column)' })
```

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

- [x] Handle non-file buffers (terminals, help, etc.)
- [x] Add commands (`:ColumnTagsReset`, `:ColumnTagsToggle`, etc.)
- [ ] Provide `<Plug>` mappings for better customization
- [ ] Visual indicator for hidden stack depth
- [ ] Column highlighting to show navigation path
- [ ] Option to persist state across Neovim sessions
- [ ] Integration with other navigation plugins

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - See LICENSE file for details
