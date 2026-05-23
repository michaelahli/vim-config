# Vim Config

> A powerful Neovim setup based on LazyVim with AI coding assistants, database tools, and cloud integrations.

[![Neovim](https://img.shields.io/badge/Neovim-0.12.2-blueviolet.svg?style=flat-square&logo=Neovim&logoColor=white)](https://neovim.io)
[![LazyVim](https://img.shields.io/badge/LazyVim-Powered-blue.svg?style=flat-square)](https://github.com/LazyVim/LazyVim)
[![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72.svg?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org)

---

## Features

### AI Coding Assistants

- **CodeCompanion** with multiple AI providers:
  - Snifox (Claude Opus 4.6)
  - Semutssh (Claude Opus 4.6)
  - Databyte (Custom models)
- **Streaming responses** for real-time feedback
- **Tool calling** with automatic error handling
- **Web search integration** (DuckDuckGo, Tavily)

### Development Tools

- **LSP** with Mason for language servers
- **Treesitter** for advanced syntax highlighting
- **Telescope** for fuzzy finding
- **Trouble** for diagnostics
- **Auto-completion** with nvim-cmp

### Database & Cloud

- **Database client** for SQL operations
- **HTTP client** for API testing
- **S3 integration** for cloud storage

### UI & Aesthetics

- Custom colorscheme
- Lualine statusline
- Snacks.nvim for UI enhancements

### Environment Variables

Create a `.env` file or set these in your shell:

```bash
export SNIFOX_API_KEY="your-snifox-key"
export SEMUTSSH_API_KEY="your-semutssh-key"
export DATABYTE_API_KEY="your-databyte-key"
export TAVILY_API_KEY="your-tavily-key"
```

---

## 🎯 Key Bindings

### AI Assistant

| Key          | Action             |
| ------------ | ------------------ |
| `<leader>aa` | Open AI chat       |
| `<leader>at` | Toggle AI inline   |
| `<leader>as` | Stop AI generation |

### File Navigation

| Key          | Action       |
| ------------ | ------------ |
| `<leader>ff` | Find files   |
| `<leader>fg` | Live grep    |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |

### LSP

| Key          | Action              |
| ------------ | ------------------- |
| `gd`         | Go to definition    |
| `gr`         | Find references     |
| `K`          | Hover documentation |
| `<leader>ca` | Code actions        |
| `<leader>rn` | Rename symbol       |

---

---

## License

MIT License - feel free to use and modify as needed.
