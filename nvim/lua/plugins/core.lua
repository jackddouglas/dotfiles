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
  },
}
