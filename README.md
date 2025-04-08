# shellcheck.nvim
[ShellCheck](https://www.shellcheck.net/) diagnostics inside Neovim.

## Features
- Asynchronous.
- No LSP involved.
- No ALE, Neomake or Syntastic needed.
- Supports sh/bash/dash/ksh.
- Runs only on `BufEnter` and `BufWritePost` events.
- Runs only when filetype is _sh_, _bash_ or _ksh_.

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
        -- Pass options to the shellcheck command.
        require 'shellcheck-nvim'.setup {
            shellcheck_options = { '-x', '--enable=all', },
        }
    end
}
```

</details>

## Available functions
Set ShellCheck diagnostics for current buffer.

```vim
:lua ShellCheck.run()
```

Clean ShellCheck diagnostics for current buffer.

```vim
:lua ShellCheck.clean()
```

## Others
Force diagnostics for some wrapper.

```bash
#!/bin/false
# shellcheck shell=<sh/ksh/dash/bash>
```
Remeber to set the filetype too.
```vim
:set ft=<sh/ksh/bash>
```
`dash` is not a valid `vim/nvim` filetype.
