return {
  {
    "olimorris/codecompanion.nvim",
    opts = {
      adapters = {
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            env = {
              api_key = "cmd:op read op://Tonk/Anthropic/credential --no-newline",
            },
          })
        end,
        tavily = function()
          return require("codecompanion.adapters").extend("tavily", {
            env = {
              api_key = "cmd:op read op://Personal/Tavily_API_Key/credential --no-newline",
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "anthropic",
        },
        inline = {
          adapter = "anthropic",
        },
      },
    },
    keys = {
      { "<C-a>", mode = { "n", "v" }, "<cmd>CodeCompanionActions<cr>", desc = "Show CodeCompanion actions" },
      { "<Leader>a", mode = { "n", "v" }, "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion" },
      { "ga", mode = { "v" }, "<cmd>CodeCompanionChat Add<cr>", desc = "Add context to CodeCompanion" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}
