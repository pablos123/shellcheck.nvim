local H = {}
local ShellCheck = {}

ShellCheck.setup = function(config)
    _G.ShellCheck = ShellCheck
    H.set_config(config)
    H.set_behaviour()
    H.shellcheck_diagnostics = {}
    H.shellcheck_output = ''
end

H.set_config = function(config)
    local default_configs = { extras = {} }
    H.config = vim.tbl_extend('force', default_configs, config or {})
end

H.has_shellcheck = function()
    return vim.fn.executable('shellcheck') == 1
end

H.shell_not_supported = function(output)
    return string.find(output, 'ShellCheck only supports sh/bash/dash/ksh')
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
    local shellcheck_autogroup = vim.api.nvim_create_augroup('shellcheck-nvim', {})
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
        pattern = '*',
        callback = function() if vim.bo.filetype == 'sh' then ShellCheck.run() end end,
        group = shellcheck_autogroup
    })

    vim.api.nvim_create_user_command('RunShellCheck', ShellCheck.run, {})
end

H.set_shellcheck_diagnostics = function()
    local buffern = vim.api.nvim_get_current_buf()
    H.parse_shellcheck_output(
        vim.fn.json_decode(H.shellcheck_output),
        buffern
    )
    vim.diagnostic.set(
        vim.api.nvim_create_namespace('shellcheck-nvim'),
        buffern,
        H.shellcheck_diagnostics,
        {}
    )
    H.shellcheck_diagnostics = {}
    H.shellcheck_output = ''
end

H.get_shellcheck_output = function(file_path)
    if not H.has_shellcheck() then return '' end
    -- local run_command = 'shellcheck --color=never --format=json ' .. H.config.extras

    local handler
    local stdout_pipe = vim.uv.new_pipe(false)

    local on_exit = vim.schedule_wrap(function()
        stdout_pipe:read_stop()
        stdout_pipe:close()
        handler:close()
        H.set_shellcheck_diagnostics()
    end
    )

    local options = {
        args = {
            '--color=never',
            '--format=json',
            '--enable=all',
            '-x',
            '--',
            file_path,
        },
        stdio = { nil, stdout_pipe, nil }
    }

    handler = vim.uv.spawn('shellcheck', options, on_exit)

    vim.uv.read_start(stdout_pipe, function(err, data)
        assert(not err, err)

        if data and not H.shell_not_supported(data) then
            local output = string.gsub(data, '\n', '')
            H.shellcheck_output = output
        end
    end)
end

H.parse_shellcheck_output = function(shellcheck_output, buffern)
    for _, sc_diag in ipairs(shellcheck_output) do
        local diagnostic = {
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
        table.insert(H.shellcheck_diagnostics, diagnostic)
    end
end

ShellCheck.run = function()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then return end

    H.get_shellcheck_output(file_path)
end

return ShellCheck
