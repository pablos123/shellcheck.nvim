
--- Tables
local H = {}
local ShellCheck = {}

ShellCheck.setup = function(config)
    _G.ShellCheck = ShellCheck
    H.set_config(config)
    H.set_behaviour()
end

H.set_config = function(config)
    local default_configs = { extras = '' }
    H.config = vim.tbl_extend('force', default_configs, config or {})
end

H.has_shellcheck = function()
    return vim.fn.executable('shellcheck') == 1
end

H.terminal_not_supported = function(output)
    return string.find(output, 'ShellCheck only supports sh/bash/dash/ksh')
end

H.get_nvim_severity = function(shellcheck_severity)
    local severity_table = {
        ['style'] = vim.diagnostic.severity.HINT,
        ['info'] =  vim.diagnostic.severity.INFO,
        ['warning'] = vim.diagnostic.severity.WARN,
        ['error'] =  vim.diagnostic.severity.ERROR,
    }
    return severity_table[shellcheck_severity]
end

H.set_behaviour = function()
    local shellcheck_autogroup = vim.api.nvim_create_augroup('shellcheck-nvim', {})
    vim.api.nvim_create_autocmd({'BufEnter', 'BufWritePost'}, {
        pattern = '*',
        callback = function() if vim.bo.filetype == 'sh' then ShellCheck.set_shellcheck_diagnostics() end end,
        group = shellcheck_autogroup
    })

    vim.api.nvim_create_user_command('RunShellCheck', ShellCheck.set_shellcheck_diagnostics, {})
end

H.get_shellcheck_output = function(file_path)
    if not H.has_shellcheck() then return '' end
    local run_command = 'shellcheck --color=never --format=json ' .. H.config.extras

    local fileh = assert(io.popen( run_command .. ' ' .. file_path))
    local output = assert(fileh:read('*a'))
    fileh:close()

    if H.terminal_not_supported(output) then return '' end

    output = string.gsub(output, '\n', '')
    return output
end

H.parse_shellcheck_output = function(shellcheck_output, buffern)
    local diagnostics_table = {}
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
        table.insert(diagnostics_table, diagnostic)
    end
    return diagnostics_table
end

--- Main
ShellCheck.set_shellcheck_diagnostics = function()
    local file_path = vim.api.nvim_buf_get_name(0)
    if file_path == '' then return end

    local shellcheck_output = H.get_shellcheck_output(file_path)
    if shellcheck_output == '' then return end

    local shellcheck_namespace = vim.api.nvim_create_namespace('shellcheck-nvim')
    local buffern = vim.api.nvim_get_current_buf()
    local diagnostics_table = H.parse_shellcheck_output(vim.fn.json_decode(shellcheck_output), buffern)
    vim.diagnostic.set(shellcheck_namespace, buffern, diagnostics_table, {})
end

return ShellCheck
