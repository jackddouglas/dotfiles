return {
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("zenwritten")

      -- brighten terminal_color_8
      vim.api.nvim_create_autocmd({ "ColorScheme" }, {
        callback = function()
          if vim.g.colors_name == "zenwritten" then
            if vim.o.background == "dark" then
              vim.g.terminal_color_8 = "#707070"
            else
              vim.g.terminal_color_8 = "#888888"
            end
          end
        end,
      })
    end,
  },
}
