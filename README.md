# shellcheck.nvim
ShellCheck diagnostics inside Neovim.

## Features
- Asynchronous.
- No LSP involved.
- No ALE, Neomake or Syntastic needed.
- Runs only on `BufEnter` and `BufWritePost` events.
- Supports sh/bash/dash/ksh.

## Dependencies
- `shellcheck` available in `$PATH`.
- `nvim 0.7` or greater.

## Install
Use your favorite plugin manager!

### lazy.nvim
```lua
{
    'pablos123/shellcheck.nvim',
    config = function () require 'shellcheck-nvim'.setup {} end
}
```

<details>
  <summary>Configure</summary>
    ```lua
    {
        'pablos123/shellcheck.nvim',
        config = function ()
            -- Pass extra arguments to the shellcheck command.
            require 'shellcheck-nvim'.setup {
                extras = { '-x', '--enable=all', },
            }
        end
    }
    ```
</details>

## Others
Run `shellcheck` in command mode.

```c
:lua ShellCheck.run()
```

Clean `shellcheck` diagnostics for current buffer.

```c
:lua ShellCheck.clean()
```

Force diagnostics for some shell or wrapper. (https://www.shellcheck.net/wiki/SC1008)
```bash
#!/bin/zsh
# shellcheck shell=bash
```
