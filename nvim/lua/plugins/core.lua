return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "zenwritten",
      news = {
        lazyvim = false,
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "ormolu",
      },
    },
  },
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[]],
        },
      },
      scroll = { enabled = false },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    dependencies = { "OXY2DEV/markview.nvim" },
  },
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        ["<C-h>"] = {
          "show",
        },
      },
    },
  },
}
