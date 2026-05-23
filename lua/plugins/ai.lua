return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      local adapters = require("codecompanion.adapters")
      require("codecompanion").setup({
        display = {
          action_palette = {
            width = 95,
            height = 10,
          },
          chat = {
            window = {
              layout = "vertical",
              width = 0.45,
            },
            show_settings = false,
            show_token_count = true,
          },
        },
        log_level = "DEBUG",
        opts = {
          log_level = "DEBUG",
          send_code = true,
          use_default_actions = true,
        },
        adapters = {
          http = {
            snifox = adapters.extend("openai_compatible", {
              name = "snifox",
              env = {
                url = "https://core.snifoxai.com/v1",
                api_key = "SNIFOX_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = {
                model = {
                  default = "anthropic/claude-opus-4.6",
                  -- default = "openai/gpt-5.3-codex",
                },
                stream = { default = true },
              },
              callbacks = {
                on_stdout = function(data)
                  vim.notify(string.format("[Snifox] Receiving data: %s", vim.inspect(data)), vim.log.levels.DEBUG)
                end,
                on_error = function(err)
                  vim.notify(
                    string.format("[Snifox API Error] %s", vim.inspect(err)),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                  vim.api.nvim_err_writeln("Snifox API failed: " .. vim.inspect(err))
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg = string.format(
                    "\n[%s] Snifox Request:\nURL: %s\nHeaders: %s\nBody: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(request.body or {})
                  )
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
              },
            }),
            semutssh = adapters.extend("openai_compatible", {
              name = "semutssh",
              env = {
                url = "https://ai.semutssh.com",
                api_key = "SEMUTSSH_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = {
                model = { default = "claude-opus-4-6" },
                stream = { default = true },
              },
              callbacks = {
                on_stdout = function(data)
                  vim.notify(string.format("[Semutssh] Receiving data: %s", vim.inspect(data)), vim.log.levels.DEBUG)
                end,
                on_error = function(err)
                  vim.notify(
                    string.format("[Semutssh API Error] %s", vim.inspect(err)),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                  vim.api.nvim_err_writeln("Semutssh API failed: " .. vim.inspect(err))
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg = string.format(
                    "\n[%s] Semutssh Request:\nURL: %s\nHeaders: %s\nBody: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(request.body or {})
                  )
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
              },
            }),
            databyte = adapters.extend("openai_compatible", {
              name = "databyte",
              env = {
                url = "https://ai.databyte.co.id/v1",
                api_key = "DATABYTE_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = {
                model = { default = "databyte-m1" },
                stream = { default = true },
              },
              callbacks = {
                on_stdout = function(data)
                  vim.notify(string.format("[Databyte] Receiving data: %s", vim.inspect(data)), vim.log.levels.DEBUG)
                end,
                on_error = function(err)
                  vim.notify(
                    string.format("[Databyte API Error] %s", vim.inspect(err)),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                  vim.api.nvim_err_writeln("Databyte API failed: " .. vim.inspect(err))
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg = string.format(
                    "\n[%s] Databyte Request:\nURL: %s\nHeaders: %s\nBody: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(request.body or {})
                  )
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
              },
            }),
            tavily = adapters.extend("tavily", {
              env = {
                api_key = "TAVILY_API_KEY",
              },
            }),
          },
        },
        interactions = {
          chat = {
            adapter = "snifox",
            tools = {
              groups = {
                agent = {
                  tools = {
                    "ddgr_search",
                    "web_search",
                  },
                },
              },
              ddgr_search = {
                description = "Search the internet using ddgr (DuckDuckGo CLI)",
                callback = function()
                  return {
                    name = "ddgr_search",
                    cmds = {},
                    schema = {
                      type = "function",
                      ["function"] = {
                        name = "ddgr_search",
                        description = "Search the internet using ddgr (DuckDuckGo CLI) and return JSON results.",
                        parameters = {
                          type = "object",
                          properties = {
                            query = {
                              type = "string",
                              description = "The search query.",
                            },
                            max_results = {
                              type = "integer",
                              description = "Maximum number of results to return. Defaults to 5.",
                            },
                          },
                          required = { "query" },
                          additionalProperties = false,
                        },
                      },
                    },
                    system_prompt = [[Use this tool when the user asks for current information from the internet, latest versions, recent news, release information, documentation lookup, or web research. Summarize the results and cite URLs from the tool output.]],
                    handlers = {
                      setup = function(self)
                        local args = self.args or {}
                        local max_results = tonumber(args.max_results) or 5
                        if max_results < 1 then
                          max_results = 1
                        elseif max_results > 10 then
                          max_results = 10
                        end

                        table.insert(self.cmds, {
                          cmd = {
                            "ddgr",
                            "--json",
                            "--num",
                            tostring(max_results),
                            args.query or "",
                          },
                        })
                      end,
                    },
                    output = {
                      cmd_string = function(self)
                        local args = self.args or {}
                        return string.format(
                          "ddgr --json --num %s %s",
                          tostring(args.max_results or 5),
                          vim.fn.shellescape(args.query or "")
                        )
                      end,
                      prompt = function(self)
                        local args = self.args or {}
                        return string.format("Search the web with ddgr for `%s`?", args.query or "")
                      end,
                      rejected = function(self, meta)
                        local helpers = require("codecompanion.interactions.chat.tools.builtin.helpers")
                        helpers.rejected(
                          self,
                          vim.tbl_extend("force", {
                            message = "The user rejected the ddgr web search",
                          }, meta or {})
                        )
                      end,
                      success = function(self, stdout, meta)
                        local chat = meta.tools.chat
                        local args = self.args or {}
                        local output = stdout and vim.iter(stdout[#stdout] or stdout):flatten():join("\n") or ""

                        if output == "" then
                          output = "[]"
                        end

                        chat:add_tool_output(
                          self,
                          string.format(
                            "Search query: %s\n\nResults JSON:\n````json\n%s\n````",
                            args.query or "",
                            output
                          ),
                          string.format("Searched the web with ddgr for `%s`", args.query or "")
                        )
                      end,
                      error = function(self, stderr, meta)
                        local chat = meta.tools.chat
                        local args = self.args or {}
                        local errors = stderr and vim.iter(stderr):flatten():join("\n") or "Unknown error"
                        chat:add_tool_output(
                          self,
                          string.format("ddgr search failed for `%s`:\n%s", args.query or "", errors)
                        )
                      end,
                    },
                    opts = {
                      require_approval_before = true,
                    },
                  }
                end,
              },
              web_search = {
                opts = {
                  adapter = "tavily",
                  opts = {
                    search_depth = "advanced",
                    max_results = 5,
                    include_answer = true,
                  },
                  require_approval_before = true,
                },
              },
            },
          },
          inline = { adapter = "snifox" },
        },
      })

      -- Command untuk membuka log file CodeCompanion
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

      -- Command untuk clear log file
      vim.api.nvim_create_user_command("CodeCompanionLogsClear", function()
        local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
        if vim.fn.filereadable(log_path) == 1 then
          vim.fn.writefile({}, log_path)
          vim.notify("Cleared CodeCompanion logs", vim.log.levels.INFO)
        end
      end, { desc = "Clear CodeCompanion log file" })
    end,
  },
}
