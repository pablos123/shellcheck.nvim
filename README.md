# shellcheck.nvim
ShellCheck diagnostics inside Neovim.

## Features
- Asynchronous.
- No LSP involved.
- No ALE, Neomake or Syntastic needed.
- Supports sh/bash/dash/ksh.
- Runs only on `BufEnter` and `BufWritePost` events.
- Runs only when filetype is _sh_.

## Dependencies
- `shellcheck` available in `$PATH`.
- `nvim >= 0.7`.

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
Set `shellcheck` diagnostics.

```c
:lua ShellCheck.run()
```

Clean `shellcheck` diagnostics.

```c
:lua ShellCheck.clean()
```

Force diagnostics for some wrapper. Remeber to set the filetype to _sh_ too.
```bash
#!/bin/false
# shellcheck shell=bash
```
