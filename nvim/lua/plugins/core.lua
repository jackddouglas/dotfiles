return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "zenwritten",
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
    opts = {
      highlight = {
        enable = true,
        disable = { "rust" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
        },
        preview = {
          treesitter = {
            enable = true,
            disable = { "rust" },
          },
        },
      },
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
