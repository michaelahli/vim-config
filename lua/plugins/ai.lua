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
                stream = {
                  default = true,
                },
                temperature = {
                  default = 0.7,
                },
                max_tokens = {
                  default = 8192,
                },
              },
              handlers = {
                chat_output = function(self, data, tools)
                  -- Custom handler to fix tool call arguments concatenation bug
                  local openai = require("codecompanion.adapters.http.openai")
                  local result = openai.handlers.chat_output(self, data, tools)

                  -- Validate and fix tool arguments after parsing
                  if tools and #tools > 0 then
                    for _, tool in ipairs(tools) do
                      if tool["function"] and tool["function"]["arguments"] then
                        local args = tool["function"]["arguments"]
                        -- Check if arguments contain multiple JSON objects concatenated
                        if type(args) == "string" and args:match("}%s*{") then
                          local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                          local log_msg = string.format(
                            "\n[%s] WARNING: Detected concatenated JSON in tool arguments!\nTool: %s\nArguments: %s\n",
                            os.date("%Y-%m-%d %H:%M:%S"),
                            tool["function"]["name"] or "unknown",
                            args
                          )
                          vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                          -- Try to extract only the first valid JSON object
                          local first_json = args:match("^(%b{})")
                          if first_json then
                            tool["function"]["arguments"] = first_json
                            vim.notify(
                              string.format(
                                "[Snifox] Fixed concatenated tool arguments for %s",
                                tool["function"]["name"]
                              ),
                              vim.log.levels.WARN
                            )
                          end
                        end
                      end
                    end
                  end

                  return result
                end,
              },
              callbacks = {
                on_stdout = function(data)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg =
                    string.format("\n[%s] Snifox Response Data:\n%s\n", os.date("%Y-%m-%d %H:%M:%S"), vim.inspect(data))
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
                on_error = function(err)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg =
                    string.format("\n[%s] Snifox ERROR 500:\n%s\n", os.date("%Y-%m-%d %H:%M:%S"), vim.inspect(err))
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                  vim.notify(
                    string.format("[Snifox] Error 500 - Check :CodeCompanionLogs for details"),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"

                  local body_content = request.body
                  if type(body_content) == "string" then
                    local ok, decoded = pcall(vim.json.decode, body_content)
                    if ok then
                      body_content = decoded
                    end
                  end

                  local log_msg = string.format(
                    "\n[%s] Snifox Request:\nURL: %s\nHeaders: %s\nBody: %s\nTools Count: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(body_content or {}),
                    body_content and body_content.tools and #body_content.tools or "0"
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
                temperature = { default = 0.7 },
                max_tokens = { default = 8192 },
              },
              handlers = {
                chat_output = function(self, data, tools)
                  local openai = require("codecompanion.adapters.http.openai")
                  local result = openai.handlers.chat_output(self, data, tools)

                  if tools and #tools > 0 then
                    for _, tool in ipairs(tools) do
                      if tool["function"] and tool["function"]["arguments"] then
                        local args = tool["function"]["arguments"]
                        if type(args) == "string" and args:match("}%s*{") then
                          local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                          local log_msg = string.format(
                            "\n[%s] WARNING: Detected concatenated JSON in tool arguments!\nTool: %s\nArguments: %s\n",
                            os.date("%Y-%m-%d %H:%M:%S"),
                            tool["function"]["name"] or "unknown",
                            args
                          )
                          vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                          local first_json = args:match("^(%b{})")
                          if first_json then
                            tool["function"]["arguments"] = first_json
                            vim.notify(
                              string.format(
                                "[Semutssh] Fixed concatenated tool arguments for %s",
                                tool["function"]["name"]
                              ),
                              vim.log.levels.WARN
                            )
                          end
                        end
                      end
                    end
                  end

                  return result
                end,
              },
              callbacks = {
                on_stdout = function(data)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg = string.format(
                    "\n[%s] Semutssh Response Data:\n%s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(data)
                  )
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
                on_error = function(err)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg =
                    string.format("\n[%s] Semutssh ERROR 500:\n%s\n", os.date("%Y-%m-%d %H:%M:%S"), vim.inspect(err))
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                  vim.notify(
                    string.format("[Semutssh] Error 500 - Check :CodeCompanionLogs for details"),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"

                  local body_content = request.body
                  if type(body_content) == "string" then
                    local ok, decoded = pcall(vim.json.decode, body_content)
                    if ok then
                      body_content = decoded
                    end
                  end

                  local log_msg = string.format(
                    "\n[%s] Semutssh Request:\nURL: %s\nHeaders: %s\nBody: %s\nTools Count: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(body_content or {}),
                    body_content and body_content.tools and #body_content.tools or "0"
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
                stream = { default = false }, -- Disable streaming when using tools
                temperature = { default = 0.7 },
                max_tokens = { default = 8192 },
              },
              handlers = {
                chat_output = function(self, data, tools)
                  local openai = require("codecompanion.adapters.http.openai")
                  local result = openai.handlers.chat_output(self, data, tools)

                  if tools and #tools > 0 then
                    for _, tool in ipairs(tools) do
                      if tool["function"] and tool["function"]["arguments"] then
                        local args = tool["function"]["arguments"]
                        if type(args) == "string" and args:match("}%s*{") then
                          local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                          local log_msg = string.format(
                            "\n[%s] WARNING: Detected concatenated JSON in tool arguments!\nTool: %s\nArguments: %s\n",
                            os.date("%Y-%m-%d %H:%M:%S"),
                            tool["function"]["name"] or "unknown",
                            args
                          )
                          vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                          local first_json = args:match("^(%b{})")
                          if first_json then
                            tool["function"]["arguments"] = first_json
                            vim.notify(
                              string.format(
                                "[Databyte] Fixed concatenated tool arguments for %s",
                                tool["function"]["name"]
                              ),
                              vim.log.levels.WARN
                            )
                          end
                        end
                      end
                    end
                  end

                  return result
                end,
              },
              callbacks = {
                on_stdout = function(data)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg = string.format(
                    "\n[%s] Databyte Response Data:\n%s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(data)
                  )
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")
                end,
                on_error = function(err)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"
                  local log_msg =
                    string.format("\n[%s] Databyte ERROR 500:\n%s\n", os.date("%Y-%m-%d %H:%M:%S"), vim.inspect(err))
                  vim.fn.writefile(vim.split(log_msg, "\n"), log_path, "a")

                  vim.notify(
                    string.format("[Databyte] Error 500 - Check :CodeCompanionLogs for details"),
                    vim.log.levels.ERROR,
                    { title = "CodeCompanion" }
                  )
                end,
                on_request = function(request)
                  local log_path = vim.fn.stdpath("log") .. "/codecompanion.log"

                  local body_content = request.body
                  if type(body_content) == "string" then
                    local ok, decoded = pcall(vim.json.decode, body_content)
                    if ok then
                      body_content = decoded
                    end
                  end

                  local log_msg = string.format(
                    "\n[%s] Databyte Request:\nURL: %s\nHeaders: %s\nBody: %s\nTools Count: %s\n",
                    os.date("%Y-%m-%d %H:%M:%S"),
                    vim.inspect(request.url or "N/A"),
                    vim.inspect(request.headers or {}),
                    vim.inspect(body_content or {}),
                    body_content and body_content.tools and #body_content.tools or "0"
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
                agent_ddgr = {
                  tools = {
                    "ddgr_search",
                    -- "web_search",
                    "ask_questions",
                    "create_file",
                    "delete_file",
                    "file_search",
                    "get_changed_files",
                    "get_diagnostics",
                    "grep_search",
                    "insert_edit_into_file",
                    "read_file",
                    "run_command",
                  },
                },
                agent_web = {
                  tools = {
                    -- "ddgr_search",
                    "web_search",
                    "ask_questions",
                    "create_file",
                    "delete_file",
                    "file_search",
                    "get_changed_files",
                    "get_diagnostics",
                    "grep_search",
                    "insert_edit_into_file",
                    "read_file",
                    "run_command",
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
