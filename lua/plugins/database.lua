return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_save_location = vim.fn.expand("~/.local/share/db_ui")

      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_winwidth = 40

      vim.g.db_ui_auto_execute_table_helpers = 1
    end,
    keys = {
      { "<leader>db", "<cmd>DBUIToggle<cr>", desc = "Toggle DBUI" },
      { "<leader>df", "<cmd>DBUIFindBuffer<cr>", desc = "Find DB Buffer" },
      { "<leader>da", "<cmd>DBUIAddConnection<cr>", desc = "Add DB Connection" },
    },
  },
}
