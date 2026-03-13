local map = vim.keymap.set

-------------------------------------------------------------------------------
-- LspAttach keymaps and features
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local b = args.buf
		map("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", { buffer = b, desc = "Go to definition" })
		map("n", "gD", "<cmd>FzfLua lsp_declarations<cr>", { buffer = b, desc = "Go to declaration" })
		map("n", "gr", "<cmd>FzfLua lsp_references<cr>", { buffer = b, desc = "Go to references" })
		map("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", { buffer = b, desc = "Go to implementations" })
		map("n", "gy", "<cmd>FzfLua lsp_typedefs<cr>", { buffer = b, desc = "Go to type definition" })
		map("n", "K", vim.lsp.buf.hover, { buffer = b, desc = "Hover" })
		map("n", "<leader>cr", vim.lsp.buf.rename, { buffer = b, desc = "Rename symbol" })
		map("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = b, desc = "Code action" })
		map("i", "<C-k>", vim.lsp.buf.signature_help, { buffer = b, desc = "Signature help" })
		map("n", "<leader>cl", "<cmd>checkhealth vim.lsp<cr>", { buffer = b, desc = "LSP info" })

		local client = vim.lsp.get_client_by_id(args.data.client_id)

		-- rust-analyzer: switch cargo target
		if client and client.name == "rust_analyzer" then
			map("n", "<leader>ct", function()
				local targets = {
					{ label = "default (host triple)", value = nil },
					{ label = "wasm32-unknown-unknown", value = "wasm32-unknown-unknown" },
					{ label = "aarch64-apple-darwin", value = "aarch64-apple-darwin" },
				}
				vim.ui.select(targets, {
					prompt = "rust-analyzer cargo target:",
					format_item = function(item)
						return item.label
					end,
				}, function(choice)
					if not choice then
						return
					end
					local target = choice.value
					local function apply(t)
						vim.lsp.config("rust_analyzer", {
							settings = {
								["rust-analyzer"] = {
									cargo = { target = t or vim.NIL },
								},
							},
						})
						-- restart all rust-analyzer clients so the new config takes effect
						for _, c in ipairs(vim.lsp.get_clients({ name = "rust_analyzer" })) do
							local bufs = vim.lsp.get_buffers_by_client_id(c.id)
							c:stop()
							vim.defer_fn(function()
								for _, buf in ipairs(bufs) do
									vim.lsp.start(vim.lsp.config.rust_analyzer, { bufnr = buf })
								end
							end, 500)
						end
						vim.notify("rust-analyzer target: " .. (t or "default"), vim.log.levels.INFO)
					end
					apply(target)
				end)
			end, { buffer = args.buf, desc = "Switch rust-analyzer target" })
		end

		-- enable inlay hints
		if client and client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
		end

		-- highlight references of symbol under cursor
		if client and client:supports_method("textDocument/documentHighlight") then
			local group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
			vim.api.nvim_clear_autocmds({ group = group, buffer = args.buf })
			vim.api.nvim_create_autocmd("CursorHold", {
				group = group,
				buffer = args.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = group,
				buffer = args.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})

-------------------------------------------------------------------------------
-- server configurations
-------------------------------------------------------------------------------
vim.lsp.config("rust_analyzer", {
	settings = {
		["rust-analyzer"] = {
			cargo = {
				features = "all",
				targetDir = true,
			},
			check = {
				command = "clippy",
			},
			diagnostics = {
				styleLints = { enable = true },
			},
			rustfmt = {
				extraArgs = { "--config", "max_width=80" },
			},
		},
	},
})

vim.lsp.enable("sourcekit")
