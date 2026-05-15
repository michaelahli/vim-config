return {
  -- Theme options (lazy-loaded; aktif saat dipilih via :colorscheme atau <leader>uC)
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "moon" } },
  { "catppuccin/nvim", name = "catppuccin", lazy = true, opts = { flavour = "mocha" } },
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "sainnhe/gruvbox-material", lazy = true },
  { "navarasu/onedark.nvim", lazy = true, opts = { style = "darker" } },
  { "Mofiqul/dracula.nvim", lazy = true },
  { "sainnhe/everforest", lazy = true },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
