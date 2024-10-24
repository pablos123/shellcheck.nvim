# shellcheck.nvim
ShellCheck diagnostics inside Neovim.

## Features
- Asynchronous.
- No LSP involved.
- No dependencies besides `shellcheck`. (No ALE, Neomake or Syntastic)
- Supports sh/bash/dash/ksh.
- Runs only on `BufEnter` and `BufWritePost` events.

## Dependencias
- `shellcheck` available in `$PATH`.
- `nvim 0.7` or greater.

## Install

Use your favorite plugin manager!

### lazy.nvim
```lua
{
    'pablos123/shellcheck.nvim',
    config = function ()
        require 'shellcheck-nvim'.setup {}
    end
}
```

## Configuration

Pass extra arguments to the `shellcheck` command.
```lua
{
    'pablos123/shellcheck.nvim',
    config = function ()
        require 'shellcheck-nvim'.setup {
            extras = {
                '-x',
                '--enable=all',
            }
        }
    end
}
```

## Others
Run `shellcheck` in command mode.

```c
:lua ShellCheck.run()
```
