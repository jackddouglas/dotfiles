return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "taake",
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
}
