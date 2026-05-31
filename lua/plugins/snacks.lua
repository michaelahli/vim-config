return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      notifier = { timeout = 3000, style = "compact" },
      scroll = { enabled = false },
      indent = { animate = { enabled = false } },
      words = { enabled = true },

      picker = {
        matcher = { frecency = true },
        exclude = { ".git/" },
        actions = {
          explorer_copy_to_paste = function(p)
            if vim.fn.mode():find("^[vV]") then
              p.list:select()
            end
            local files = {}
            for _, item in ipairs(p:selected({ fallback = true })) do
              table.insert(files, Snacks.picker.util.path(item))
            end
            p.list:set_selected()
            local value = table.concat(files, "\n")
            vim.fn.setreg(vim.v.register or "+", value, "l")
            _G.__explorer_clipboard = { items = files, mode = "copy" }
            Snacks.notify.info("Copied " .. #files .. " file(s) to clipboard")
          end,
          explorer_cut_to_paste = function(p)
            if vim.fn.mode():find("^[vV]") then
              p.list:select()
            end
            local files = {}
            for _, item in ipairs(p:selected({ fallback = true })) do
              table.insert(files, Snacks.picker.util.path(item))
            end
            p.list:set_selected()
            local value = table.concat(files, "\n")
            vim.fn.setreg(vim.v.register or "+", value, "l")
            _G.__explorer_clipboard = { items = files, mode = "cut" }
            Snacks.notify.info("Cut " .. #files .. " file(s) to clipboard")
          end,
          explorer_paste_from_clipboard = function(p)
            local files = {}
            if _G.__explorer_clipboard and #_G.__explorer_clipboard.items > 0 then
              files = _G.__explorer_clipboard.items
            else
              files = vim.split(vim.fn.getreg(vim.v.register or "+") or "", "\n", { plain = true })
              files = vim.tbl_filter(function(file)
                return file ~= "" and (vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1)
              end, files)
            end
            if #files == 0 then
              return Snacks.notify.warn("No files to paste")
            end
            local dir = svim.fs.normalize(p:dir())
            local mode = _G.__explorer_clipboard and _G.__explorer_clipboard.mode or "copy"
            if mode == "cut" then
              for _, from in ipairs(files) do
                local to = svim.fs.normalize(dir .. "/" .. vim.fn.fnamemodify(from, ":t"))
                if vim.fn.filereadable(to) == 1 or vim.fn.isdirectory(to) == 1 then
                  Snacks.notify.warn("Already exists: " .. vim.fn.fnamemodify(to, ":."))
                else
                  Snacks.rename.rename_file({ from = from, to = to })
                end
              end
              _G.__explorer_clipboard = nil
            else
              Snacks.picker.util.copy(files, dir)
            end
            local Tree = require("snacks.explorer.tree")
            Tree:refresh(dir)
            Tree:open(dir)
            require("snacks.explorer.actions").update(p, { target = dir })
          end,
        },
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            exclude = { ".git/" },
            win = {
              list = {
                keys = {
                  ["c"] = "explorer_copy_to_paste",
                  ["x"] = "explorer_cut_to_paste",
                  ["p"] = "explorer_paste_from_clipboard",
                },
              },
            },
          },
          files = {
            hidden = true,
            ignored = false,
          },
          grep = {
            hidden = true,
            ignored = true,
          },
        },
      },

      dashboard = {
        preset = {
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Grep", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Config",
              action = ":lua Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })",
            },
            { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>gg",
        function()
          local file = vim.api.nvim_buf_get_name(0)
          local dir = (file ~= "" and vim.fn.filereadable(file) == 1) and vim.fs.dirname(file) or vim.fn.getcwd()
          local root = vim.fs.root(dir, ".git") or dir
          Snacks.lazygit({ cwd = root })
        end,
        desc = "Lazygit (buffer dir)",
      },
      {
        "<leader>gb",
        function()
          Snacks.git.blame_line()
        end,
        desc = "Git Blame Line",
      },
      {
        "<leader>gB",
        function()
          Snacks.gitbrowse()
        end,
        desc = "Git Browse (open in browser)",
      },
      {
        "<leader>.",
        function()
          Snacks.scratch()
        end,
        desc = "Toggle Scratch Buffer",
      },
      {
        "<leader>S",
        function()
          Snacks.scratch.select()
        end,
        desc = "Select Scratch Buffer",
      },
      {
        "<leader>n",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      {
        "<leader>un",
        function()
          Snacks.notifier.hide()
        end,
        desc = "Dismiss All Notifications",
      },
      {
        "<leader>cR",
        function()
          Snacks.rename.rename_file()
        end,
        desc = "Rename File",
      },
      {
        "<leader>bd",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },

      {
        "<c-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle Terminal",
      },
      {
        "<c-_>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle Terminal (which-key fix)",
      },

      {
        "]]",
        function()
          Snacks.words.jump(vim.v.count1)
        end,
        desc = "Next Reference",
        mode = { "n", "t" },
      },
      {
        "[[",
        function()
          Snacks.words.jump(-vim.v.count1)
        end,
        desc = "Prev Reference",
        mode = { "n", "t" },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd
        end,
      })
    end,
  },
}
