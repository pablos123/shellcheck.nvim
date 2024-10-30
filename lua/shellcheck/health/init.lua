local M = {}

M.check = function()
    vim.health.start('shellcheck.nvim')
    if vim.fn.executable('shellcheck') == 1 then
        vim.health.ok('shellcheck found in $PATH')
    else
        vim.health.error('shellcheck not found in $PATH')
    end

    if vim.fn.has('nvim-0.7') == 1 then
        vim.health.ok('nvim >= 0.7')
    else
        vim.health.error('nvim version is below 0.7')
    end
end

return M
