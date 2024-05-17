return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	init = function()
		vim.o.timeout = true
		vim.o.timeoutlen = 500
	end,
	opts = {
		plugins = { spelling = true },
		defaults = {
			mode = { "n", "v" },
			["g"] = { name = "+goto" },
			["gs"] = { name = "+surround" },
			["z"] = { name = "+fold" },
			["["] = { name = "+next" },
			["]"] = { name = "+prev" },
			["<leader>c"] = { name = "+code" },
			["<leader>e"] = { name = "+explorer" },
			["<leader>f"] = { name = "+files" },
			["<leader>r"] = { name = "+rename" },
			["<leader>s"] = { name = "+session" },
			["<leader>t"] = { name = "+tabs" },
			["<leader>w"] = { name = "+windows" },
			["<leader>x"] = { name = "+diagnostics" },
		},
	},
}
