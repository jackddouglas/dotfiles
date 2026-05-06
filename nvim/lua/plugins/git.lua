return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		keys = {
			{ "<leader>ghd", "<cmd>DiffviewOpen -- %<cr>", desc = "Diff this" },
			{ "<leader>ghD", "<cmd>DiffviewOpen HEAD~ -- %<cr>", desc = "Diff this ~" },
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff working tree" },
			{ "<leader>gB", "<cmd>DiffviewOpen origin/main...HEAD<cr>", desc = "Diff branch vs origin/main" },
			{ "<leader>gl", "<cmd>DiffviewFileHistory<cr>", desc = "File history (repo)" },
			{ "<leader>gL", "<cmd>DiffviewFileHistory %<cr>", desc = "File history (current file)" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
		},
	},
	{
		"NeogitOrg/neogit",
		lazy = true,
		dependencies = {
			"sindrets/diffview.nvim",
			"ibhagwan/fzf-lua",
		},
		cmd = "Neogit",
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" },
		},
	},
}
