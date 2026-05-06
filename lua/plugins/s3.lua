-- S3 Viewer for LazyVim/Neovim
--
-- Commands:
--   :S3List [s3://bucket/prefix/]
--   :S3View s3://bucket/path/to/file
--   :S3Upload s3://bucket/path/to/destination
--   :S3Delete s3://bucket/path/to/file
--   :S3Save [s3://bucket/path/to/file]
--   :S3Browse [s3://bucket/prefix/]
--
-- Notes:
--   - Uses AWS CLI under the hood.
--   - Supports S3-compatible storage with self-signed certificates via --no-verify-ssl.
--   - S3View downloads to a temporary file, loads it into a buffer, then deletes the temp file.

return {
  {
    dir = ".",
    name = "s3-viewer",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      local config = {
        skip_ssl = true,
      }

      local filetypes = {
        bash = "bash",
        csv = "csv",
        css = "css",
        go = "go",
        hcl = "hcl",
        html = "html",
        java = "java",
        js = "javascript",
        json = "json",
        log = "log",
        lua = "lua",
        md = "markdown",
        py = "python",
        rb = "ruby",
        rs = "rust",
        sh = "sh",
        sql = "sql",
        tf = "terraform",
        toml = "toml",
        ts = "typescript",
        txt = "text",
        xml = "xml",
        yaml = "yaml",
        yml = "yaml",
      }

      local function notify(message, level)
        vim.notify(message, level or vim.log.levels.INFO)
      end

      local function aws_s3_cmd()
        if config.skip_ssl then
          return "aws --no-verify-ssl s3"
        end
        return "aws s3"
      end

      local function normalize_s3_path(path)
        path = vim.trim(path or "")

        if path == "" or path == "s3://" then
          return "s3://"
        end

        if path:match("^s3://") then
          return path
        end

        return "s3://" .. path:gsub("^/+", "")
      end

      local function ensure_prefix_path(path)
        path = normalize_s3_path(path)

        if path ~= "s3://" and not path:match("/$") then
          path = path .. "/"
        end

        return path
      end

      local function shellescape(value)
        return vim.fn.shellescape(value)
      end

      local function run_system(cmd)
        local output = vim.fn.system(cmd)

        return {
          ok = vim.v.shell_error == 0,
          output = output,
          code = vim.v.shell_error,
        }
      end

      local function run_systemlist(cmd)
        local output = vim.fn.systemlist(cmd)

        return {
          ok = vim.v.shell_error == 0,
          output = output,
          code = vim.v.shell_error,
        }
      end

      local function run_with_stderr_file(cmd)
        local errfile = vim.fn.tempname()
        local result = run_system(cmd .. " 2>" .. shellescape(errfile))
        local stderr = table.concat(vim.fn.readfile(errfile), "\n")

        pcall(vim.fn.delete, errfile)

        result.stderr = stderr
        return result
      end

      local function open_scratch_buffer(name, lines, opts)
        opts = opts or {}

        vim.cmd("new")
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.swapfile = false
        vim.bo.modifiable = opts.modifiable ~= false
        vim.api.nvim_buf_set_name(0, name)

        if opts.s3path then
          vim.b.s3_path = opts.s3path
        end
      end

      local function set_filetype_from_path(path)
        local ext = path:match("%.([^%.]+)$")
        if not ext then
          return
        end

        if filetypes[ext] then
          vim.bo.filetype = filetypes[ext]
        else
          vim.cmd("filetype detect")
        end
      end

      local function parent_s3_path(path)
        path = ensure_prefix_path(path)

        local stripped = path:gsub("/$", "")
        local parent = stripped:match("(.+/)")

        if parent and parent:len() >= 5 then
          return parent
        end

        return "s3://"
      end

      local function parse_s3_ls_line(base_path, line)
        if line == "" then
          return nil
        end

        local prefix = line:match("^%s*PRE%s+(.+)$")
        if prefix then
          return {
            display = "📁 " .. prefix,
            name = prefix,
            path = base_path .. prefix,
            is_dir = true,
          }
        end

        local filename = line:match("^%d%d%d%d%-%d%d%-%d%d%s+%d%d:%d%d:%d%d%s+%d+%s+(.+)$")
        if filename then
          return {
            display = "📄 " .. line,
            name = filename,
            path = base_path .. filename,
            is_dir = false,
          }
        end

        return nil
      end

      local function list_s3(path)
        path = normalize_s3_path(path)

        notify("Listing " .. path .. " ...")

        local result = run_system(aws_s3_cmd() .. " ls " .. shellescape(path))
        if not result.ok then
          notify("S3List error: " .. result.output, vim.log.levels.ERROR)
          return
        end

        open_scratch_buffer(path, vim.split(result.output, "\n"))
        notify("Listed: " .. path)
      end

      local function view_s3_file(s3path)
        s3path = normalize_s3_path(s3path)

        if s3path == "s3://" then
          notify("Usage: :S3View s3://bucket/path/to/file", vim.log.levels.WARN)
          return
        end

        notify("Loading into buffer: " .. s3path .. " ...")

        local tmpfile = vim.fn.tempname()
        local cmd = table.concat({
          aws_s3_cmd(),
          "cp",
          shellescape(s3path),
          shellescape(tmpfile),
        }, " ")

        local result = run_with_stderr_file(cmd)
        if not result.ok then
          pcall(vim.fn.delete, tmpfile)
          notify("S3View error for `" .. s3path .. "`: " .. result.stderr, vim.log.levels.ERROR)
          return
        end

        local lines = vim.fn.readfile(tmpfile, "b")
        pcall(vim.fn.delete, tmpfile)

        open_scratch_buffer(s3path, lines, { s3path = s3path })
        set_filetype_from_path(s3path)
        vim.bo.modified = false
        notify("Loaded: " .. s3path)
      end

      local function save_s3_buffer(s3path)
        s3path = normalize_s3_path(s3path or vim.b.s3_path)

        if s3path == "s3://" then
          notify("Usage: :S3Save s3://bucket/path/to/file", vim.log.levels.WARN)
          return
        end

        local tmpfile = vim.fn.tempname()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        vim.fn.writefile(lines, tmpfile, "b")

        local cmd = table.concat({
          aws_s3_cmd(),
          "cp",
          shellescape(tmpfile),
          shellescape(s3path),
        }, " ")

        notify("Saving buffer to " .. s3path .. " ...")

        local result = run_with_stderr_file(cmd)
        pcall(vim.fn.delete, tmpfile)

        if not result.ok then
          notify("S3Save error for `" .. s3path .. "`: " .. result.stderr, vim.log.levels.ERROR)
          return
        end

        vim.b.s3_path = s3path
        vim.bo.modified = false
        notify("Saved: " .. s3path)
      end

      local function upload_s3_file(s3path)
        s3path = normalize_s3_path(s3path)

        if s3path == "s3://" then
          notify("Usage: :S3Upload s3://bucket/path/to/dest", vim.log.levels.WARN)
          return
        end

        local filepath = vim.fn.expand("%:p")
        if filepath == "" then
          notify("No file to upload (buffer has no file path)", vim.log.levels.ERROR)
          return
        end

        notify("Uploading " .. filepath .. " to " .. s3path .. " ...")

        local cmd = table.concat({
          aws_s3_cmd(),
          "cp",
          shellescape(filepath),
          shellescape(s3path),
        }, " ")

        local result = run_system(cmd)
        if not result.ok then
          notify("S3Upload error: " .. result.output, vim.log.levels.ERROR)
          return
        end

        notify("Uploaded to " .. s3path)
      end

      local function delete_s3_file(s3path)
        s3path = normalize_s3_path(s3path)

        if s3path == "s3://" then
          notify("Usage: :S3Delete s3://bucket/path/to/file", vim.log.levels.WARN)
          return
        end

        local confirm = vim.fn.confirm("Delete " .. s3path .. "?", "&Yes\n&No", 2)
        if confirm ~= 1 then
          notify("Cancelled")
          return
        end

        local result = run_system(aws_s3_cmd() .. " rm " .. shellescape(s3path))
        if not result.ok then
          notify("S3Delete error: " .. result.output, vim.log.levels.ERROR)
          return
        end

        notify("Deleted: " .. s3path)
      end

      local function browse_s3(path)
        local ok = pcall(require, "telescope")
        if not ok then
          notify("Telescope not found! Install telescope.nvim first.", vim.log.levels.ERROR)
          return
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        path = ensure_prefix_path(path)
        notify("Loading " .. path .. " ...")

        local result = run_systemlist(aws_s3_cmd() .. " ls " .. shellescape(path))
        if not result.ok then
          notify("S3Browse error: " .. table.concat(result.output, "\n"), vim.log.levels.ERROR)
          return
        end

        local parent_path = parent_s3_path(path)
        local items = {
          {
            display = "..",
            name = "..",
            path = parent_path,
            is_dir = true,
          },
        }

        for _, line in ipairs(result.output) do
          local item = parse_s3_ls_line(path, line)
          if item then
            table.insert(items, item)
          end
        end

        pickers
          .new({}, {
            prompt_title = "S3: " .. path,
            finder = finders.new_table({
              results = items,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.display,
                  ordinal = entry.name,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr, map)
              local function open_selection()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if not selection then
                  return
                end

                local item = selection.value
                if item.is_dir then
                  browse_s3(item.path)
                else
                  view_s3_file(item.path)
                end
              end

              local function go_parent()
                actions.close(prompt_bufnr)
                browse_s3(parent_path)
              end

              local function delete_selection()
                local selection = action_state.get_selected_entry()

                if not selection then
                  return
                end

                local item = selection.value
                if item.is_dir then
                  notify("Delete folder/prefix is not supported from browse", vim.log.levels.WARN)
                  return
                end

                actions.close(prompt_bufnr)
                delete_s3_file(item.path)
                browse_s3(path)
              end

              actions.select_default:replace(open_selection)
              map("n", "<BS>", go_parent)
              map("i", "<C-h>", go_parent)
              map("n", "dd", delete_selection)
              map("i", "<C-d>", delete_selection)

              return true
            end,
          })
          :find()
      end

      vim.api.nvim_create_user_command("S3List", function(opts)
        list_s3(opts.args ~= "" and opts.args or "s3://")
      end, { nargs = "?", desc = "List S3 objects" })

      vim.api.nvim_create_user_command("S3View", function(opts)
        view_s3_file(opts.args)
      end, { nargs = 1, desc = "View S3 file" })

      vim.api.nvim_create_user_command("S3Save", function(opts)
        save_s3_buffer(opts.args ~= "" and opts.args or nil)
      end, { nargs = "?", desc = "Save current buffer to S3" })

      vim.api.nvim_create_user_command("S3Upload", function(opts)
        upload_s3_file(opts.args)
      end, { nargs = 1, desc = "Upload file to S3" })

      vim.api.nvim_create_user_command("S3Delete", function(opts)
        delete_s3_file(opts.args)
      end, { nargs = 1, desc = "Delete S3 file" })

      vim.api.nvim_create_user_command("S3Browse", function(opts)
        local path = opts.args

        if path == "" then
          path = vim.fn.input("S3 Path (e.g. s3://bucket/prefix/): ")
          if path == "" then
            return
          end
        end

        browse_s3(path)
      end, { nargs = "?", desc = "Browse S3 with Telescope" })
    end,
  },
}
