return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      "kristijanhusak/vim-dadbod",
      "tpope/vim-dadbod",
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBSelect",
    },
    init = function()
      vim.g.db_ui_echo_commands = true
      vim.g.db_ui_show_help = 1
      vim.g.db_ui_win_border = "rounded"
      vim.g.db_ui_save_location = "~/.local/share/db_ui"
    end,
    config = function()
      require("dadbod").setup({
        default_url = "",
        default_connector = "mysql",
        default_timeout = 5000,
      })

      require("dadbod-ui").setup({
        split_orientation = "horizontal",
        split_size = 0.4,
        auto_execute = false,
        execute_query_on_enter = false,
        show_icon_column = true,
        reset_connection_on_save = false,
        ignore_closing_windows = false,
        select_in_split = true,
        picker = "telescope",
      })
    end,
  },

  {
    "kristijanhusak/vim-dadbod",
    ft = "sql",
    dependencies = {
      "tpope/vim-dadbod",
    },
  },

  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
    dependencies = {
      "kristijanhusak/vim-dadbod",
    },
    config = function()
      vim.g.db_ui_completion_use_nvim_cmp = true
    end,
  },
}
