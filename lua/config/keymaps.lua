-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>ci", "<cmd>CodeCompanionChat Toggle<cr>", {
  desc = "Toggle CodeCompanion Chat",
})

vim.keymap.set("n", "<leader>Sl", ":S3List ", { desc = "S3 List" })
vim.keymap.set("n", "<leader>Sv", ":S3View ", { desc = "S3 View file" })
vim.keymap.set("n", "<leader>Su", ":S3Upload ", { desc = "S3 Upload file" })
vim.keymap.set("n", "<leader>Sd", ":S3Delete ", { desc = "S3 Delete file" })
vim.keymap.set("n", "<leader>Sb", ":S3Browse ", { desc = "S3 Browse (Telescope)" })
vim.keymap.set("n", "<leader>Ss", ":S3Save", { desc = "S3 Save" })

vim.keymap.set("n", "<leader>db", "<cmd>DBSelect<cr>", { desc = "Select Database" })
vim.keymap.set("n", "<leader>du", "<cmd>DBUI<cr>", { desc = "Open Database UI" })
vim.keymap.set("n", "<leader>dt", "<cmd>DBUIToggle<cr>", { desc = "Toggle Database UI" })
vim.keymap.set("n", "<leader>da", "<cmd>DBUIAddConnection<cr>", { desc = "Add Database Connection" })
vim.keymap.set("n", "<leader>df", "<cmd>DBUIFindBuffer<cr>", { desc = "Find Database Buffer" })
vim.keymap.set("n", "<leader>W", "<Plug>(DBUI_SaveQuery)")

vim.keymap.set("n", "<leader>cb", function()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP clients attached to current buffer", vim.log.levels.WARN)
    return
  end
  local names = {}
  for _, client in ipairs(clients) do
    names[#names + 1] = client.name
  end
  vim.cmd("lsp restart " .. table.concat(names, " "))
  vim.notify("Restarted LSP: " .. table.concat(names, ", "))
end, { desc = "Restart LSP (buffer)" })
