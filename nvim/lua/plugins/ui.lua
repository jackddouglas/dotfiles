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
    keys = {
      {
        "<c-h>",
        function()
          TmuxNavigateIgnore("TmuxNavigateLeft", "nofile")
        end,
      },
      {
        "<c-j>",
        function()
          TmuxNavigateIgnore("TmuxNavigateDown", "nofile")
        end,
      },
      {
        "<c-k>",
        function()
          TmuxNavigateIgnore("TmuxNavigateUp", "nofile")
        end,
      },
      {
        "<c-l>",
        function()
          TmuxNavigateIgnore("TmuxNavigateRight", "nofile")
        end,
      },
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
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
