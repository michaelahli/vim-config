return {
  -- for typescript, LazyVim includes extra specs to properly setup lspconfig,
  -- treesitter and mason. So instead of a custom LSP spec, you can use:
  { import = "lazyvim.plugins.extras.lang.typescript" },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },
}
