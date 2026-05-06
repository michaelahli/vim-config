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
