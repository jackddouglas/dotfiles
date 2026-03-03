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
