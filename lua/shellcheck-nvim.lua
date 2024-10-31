-- Tables
local H = {}
local ShellCheck = {}

-- ShellCheck
function ShellCheck.setup(config)
    _G.ShellCheck = ShellCheck
    H:set_config(config)
    H:set_behaviour()
end

function ShellCheck.run()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then return end
    H:get_shellcheck_output(file_path, vim.api.nvim_get_current_buf())
end

function ShellCheck.clean()
    H:set_shellcheck_diagnostics('[]', vim.api.nvim_get_current_buf())
end

-- Helper
function H.has_shellcheck()
    return vim.fn.executable('shellcheck') == 1
end

function H.file_exists(file_path)
    return vim.fn.filereadable(file_path) == 1
end

function H.shell_supported(output)
    return not string.find(output, 'ShellCheck only supports sh/bash/dash/ksh')
end

function H.print_error(error)
    vim.api.nvim_err_writeln('ShellCheck: ' .. error)
end

function H.get_nvim_severity(shellcheck_severity)
    local severity_table = {
        ['style'] = vim.diagnostic.severity.HINT,
        ['info'] = vim.diagnostic.severity.INFO,
        ['warning'] = vim.diagnostic.severity.WARN,
        ['error'] = vim.diagnostic.severity.ERROR,
    }
    return severity_table[shellcheck_severity]
end

function H:set_config(config)
    local default_configs = { extras = {} }
    self.config = vim.tbl_extend('force', default_configs, config or {})
end

function H:set_behaviour()
    local shellcheck_autogroup = vim.api.nvim_create_augroup(
        'shellcheck-nvim',
        {}
    )

    local events = { 'BufEnter', 'BufWritePost' }

    local run_shellcheck = function()
        if vim.bo.filetype == 'sh' then ShellCheck.run() end
    end

    vim.api.nvim_create_autocmd(events, {
        pattern = '*',
        callback = run_shellcheck,
        group = shellcheck_autogroup
    })
end

function H:handle_shellcheck_exit_code(code)
    if code == 2 then
        self.print_error('Some files could not be processed.')
    elseif code == 3 then
        self.print_error('Invoked with bad syntax.')
    elseif code == 4 then
        self.print_error('Invoked with bad options.')
    end
end

function H:prepare_args(file_path)
    local shellcheck_args = {
        '--color=never',
        '--format=json',
    }
    for _, extra_arg in ipairs(self.config.extras) do
        table.insert(shellcheck_args, extra_arg)
    end
    table.insert(shellcheck_args, '--')
    table.insert(shellcheck_args, file_path)
    return shellcheck_args
end

function H:get_shellcheck_output(file_path, buffern)
    if not self.file_exists(file_path) then return end

    if not self.has_shellcheck() then
        self.print_error('shellcheck not found in PATH.')
        return
    end

    -- Async thread, main logic is here
    local shellcheck_output = ''
    local handler
    local stdout_pipe = vim.uv.new_pipe(false)

    -- Execute on shellcheck exit. Append the call to nvim's main loop.
    local on_exit = vim.schedule_wrap(function(code)
        self:handle_shellcheck_exit_code(code)
        stdout_pipe:read_stop()
        stdout_pipe:close()
        handler:close()

        -- If shell is not supported clean diagnostics on buffer.
        -- This handles the case of changing the shell on the go.
        if shellcheck_output == '' then shellcheck_output = '[]' end

        self:set_shellcheck_diagnostics(shellcheck_output, buffern)
    end
    )

    local options = {
        args = self:prepare_args(file_path),
        stdio = { nil, stdout_pipe, nil }
    }

    handler = vim.uv.spawn('shellcheck', options, on_exit)

    --  The callback will be made several times until there
    --  is no more data to read or uv.read_stop() is called.
    stdout_pipe:read_start(function(err, data)
        assert(not err, err)

        if data and self.shell_supported(data) then
            -- If json is too large I want to append the output
            shellcheck_output = shellcheck_output .. string.gsub(data, '\n', '')
        end
    end)
end

function H:set_shellcheck_diagnostics(shellcheck_output, buffern)
    assert(shellcheck_output)
    assert(shellcheck_output ~= '')

    local diagnosticss = self:create_nvim_diagnostics(
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

function H:create_nvim_diagnostics(shellcheck_diagnostics, buffern)
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
            severity = self.get_nvim_severity(sc_diag.level),
            source = 'shellcheck-nvim',
        }
        table.insert(nvim_diagnostics, nvim_diagnostic)
    end
    return nvim_diagnostics
end

return ShellCheck
