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
        adapters = {
          http = {
            snifox = adapters.extend("openai_compatible", {
              name = "snifox",
              env = {
                url = "https://core.snifoxai.com/v1",
                api_key = "SNIFOX_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = { model = { default = "openai/gpt-5.3-codex" } },
            }),
            semutssh = adapters.extend("openai_compatible", {
              name = "semutssh",
              env = {
                url = "https://ai.semutssh.com",
                api_key = "SEMUTSSH_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = { model = { default = "claude-opus-4-6" } },
            }),
            databyte = adapters.extend("openai_compatible", {
              name = "databyte",
              env = {
                url = "https://ai.databyte.co.id/v1",
                api_key = "DATABYTE_API_KEY",
                chat_url = "/chat/completions",
              },
              schema = { model = { default = "databyte-m1" } },
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
            adapter = "semutssh",
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
          inline = { adapter = "semutssh" },
        },
      })
    end,
  },
}
