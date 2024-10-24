-- Tables
local H = {}
local ShellCheck = {}

-- ShellCheck
ShellCheck.setup = function(config)
    _G.ShellCheck = ShellCheck
    H.set_config(config)
    H.set_behaviour()
end

ShellCheck.run = function()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then return end
    H.get_shellcheck_output(file_path, vim.api.nvim_get_current_buf())
end

-- Helpers
H.set_config = function(config)
    local default_configs = { extras = {} }
    H.config = vim.tbl_extend('force', default_configs, config or {})
end

H.has_shellcheck = function()
    return vim.fn.executable('shellcheck') == 1
end

H.shell_supported = function(output)
    return not string.find(output, 'ShellCheck only supports sh/bash/dash/ksh')
end

H.print_error = function(error)
    vim.api.nvim_err_writeln('ShellCheck: ' .. error)
end

H.get_nvim_severity = function(shellcheck_severity)
    local severity_table = {
        ['style'] = vim.diagnostic.severity.HINT,
        ['info'] = vim.diagnostic.severity.INFO,
        ['warning'] = vim.diagnostic.severity.WARN,
        ['error'] = vim.diagnostic.severity.ERROR,
    }
    return severity_table[shellcheck_severity]
end

H.set_behaviour = function()
    local shellcheck_autogroup = vim.api.nvim_create_augroup(
        'shellcheck-nvim',
        {}
    )
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
        pattern = '*',
        callback = function()
            if vim.bo.filetype == 'sh' then
                ShellCheck.run()
            end
        end,
        group = shellcheck_autogroup
    })
end

H.handle_shellcheck_exit_code = function(code)
    if code == 2 then
        H.print_error('Some files could not be processed.')
    elseif code == 3 then
        H.print_error('Invoked with bad syntax.')
    elseif code == 4 then
        H.print_error('Invoked with bad options.')
    end
end

H.prepare_args = function(file_path)
    local shellcheck_args = {
        '--color=never',
        '--format=json',
    }
    for _, extra_arg in ipairs(H.config.extras) do
        table.insert(shellcheck_args, extra_arg)
    end
    table.insert(shellcheck_args, '--')
    table.insert(shellcheck_args, file_path)
    return shellcheck_args
end

H.get_shellcheck_output = function(file_path, buffern)
    if not H.has_shellcheck() then
        H.print_error('shellcheck not found in PATH.')
        return
    end

    -- Async thread
    -- If shell is not supported clean diagnostics on buffer.
    -- This handles the case of changing the shell on the go.
    local shellcheck_output = '[]'

    local handler
    local stdout_pipe = vim.uv.new_pipe(false)

    -- Execute on shellcheck exit. Append the call to nvim's main loop.
    local on_exit = vim.schedule_wrap(function(code)
        H.handle_shellcheck_exit_code(code)
        stdout_pipe:read_stop()
        stdout_pipe:close()
        handler:close()
        H.set_shellcheck_diagnostics(shellcheck_output, buffern)
    end
    )

    local options = {
        args = H.prepare_args(file_path),
        stdio = { nil, stdout_pipe, nil }
    }

    handler = vim.uv.spawn('shellcheck', options, on_exit)

    --  The callback will be made several times until there
    --  is no more data to read or uv.read_stop() is called.
    stdout_pipe:read_start(function(err, data)
        assert(not err, err)

        if data and H.shell_supported(data) then
            shellcheck_output = string.gsub(data, '\n', '')
        end
    end)
end

H.set_shellcheck_diagnostics = function(shellcheck_output, buffern)
    assert(shellcheck_output)
    assert(shellcheck_output ~= '')

    local diagnosticss = H.create_nvim_diagnostics(
        vim.fn.json_decode(shellcheck_output),
        buffern
    )
    vim.diagnostic.set(
        vim.api.nvim_create_namespace('shellcheck-nvim'),
        buffern,
        diagnosticss,
        {}
    )
end

H.create_nvim_diagnostics = function(shellcheck_diagnostics, buffern)
    assert(shellcheck_diagnostics)

    local nvim_diagnostics = {}
    for _, sc_diag in ipairs(shellcheck_diagnostics) do
        local nvim_diagnostic = {
            bufnr = buffern,
            lnum = sc_diag.line - 1,
            end_lnum = sc_diag.endLine - 1,
            col = sc_diag.column - 1,
            end_col = sc_diag.endColumn - 1,
            message = sc_diag.message,
            code = 'https://www.shellcheck.net/wiki/SC' .. sc_diag.code,
            severity = H.get_nvim_severity(sc_diag.level),
            source = 'shellcheck-nvim',
        }
        table.insert(nvim_diagnostics, nvim_diagnostic)
    end
    return nvim_diagnostics
end

return ShellCheck
