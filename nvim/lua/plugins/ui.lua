local TmuxNavigateIgnore = function(motion, buftype)
  vim.g.last_pane = vim.fn.win_getid()
  vim.cmd(motion)
  if vim.bo.buftype ~= buftype then
    vim.g.last_pane = vim.fn.win_getid()
  else
    while vim.bo.buftype == buftype do
      local jumped_to = vim.fn.win_getid()
      vim.cmd(motion)
      if vim.fn.win_getid() == jumped_to then
        vim.fn.win_gotoid(vim.g.last_pane)
        break
      end
    end
  end
end

return {
  {
    "shortcuts/no-neck-pain.nvim",
    version = "*",
    opts = {
      width = 150,
      autocmds = {
        -- enableOnVimEnter = "safe",
        -- skipEnteringNoNeckPainBuffer = true,
      },
      -- integrations = {
      --   dashboard = {
      --     enabled = true,
      --     filetypes = { "snacks_dashboard" },
      --   },
      -- },
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
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1

      local function set_keymaps()
        vim.keymap.set({ "n", "t" }, "<c-h>", function()
          TmuxNavigateIgnore("TmuxNavigateLeft", "nofile")
        end)
        vim.keymap.set({ "n", "t" }, "<c-j>", function()
          TmuxNavigateIgnore("TmuxNavigateDown", "nofile")
        end)
        vim.keymap.set({ "n", "t" }, "<c-k>", function()
          TmuxNavigateIgnore("TmuxNavigateUp", "nofile")
        end)
        vim.keymap.set({ "n", "t" }, "<c-l>", function()
          TmuxNavigateIgnore("TmuxNavigateRight", "nofile")
        end)
      end

      set_keymaps()

      vim.api.nvim_create_autocmd("TermOpen", {
        callback = set_keymaps,
      })

      -- These autocommands will focus on the last buffer that was not ignored, when we go from a tmux pane to a vim split
      vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained", "TabEnter" }, {
        pattern = { "*" },
        callback = function()
          vim.fn.win_gotoid(vim.g.last_pane)
        end,
      })
    end,
  },
}
