-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_user_command("CodeCompanionLogs", function()
  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
  if vim.fn.filereadable(log_path) == 1 then
    vim.cmd("tabnew " .. log_path)
    vim.cmd("setlocal autoread")
    vim.notify("Opened CodeCompanion logs", vim.log.levels.INFO)
  else
    vim.notify("Log file not found: " .. log_path, vim.log.levels.WARN)
  end
end, { desc = "Open CodeCompanion log file" })

vim.api.nvim_create_user_command("CodeCompanionLogsClear", function()
  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
  if vim.fn.filereadable(log_path) == 1 then
    vim.fn.writefile({}, log_path)
    vim.notify("Cleared CodeCompanion logs", vim.log.levels.INFO)
  end
end, { desc = "Clear CodeCompanion log file" })
