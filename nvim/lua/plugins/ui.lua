return {
  {
    "shortcuts/no-neck-pain.nvim",
    version = "*",
    opts = {
      width = 150,
      autocmds = {
        enableOnVimEnter = "safe",
      },
      integrations = {
        dashboard = {
          enabled = true,
          filetypes = { "snacks_dashboard" },
        },
      },
      mappings = {
        enabled = true,
        toggle = "<leader>unp",
        toggleLeftSide = "<leader>unl",
        toggleRightSide = "<leader>unr",
        widthUp = "<leader>un=",
        widthDown = "<leader>un-",
        scratchPad = "<leader>uns",
      },
    },
  },
}
