return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	event = { "BufLeave" },
	config = function()
		-- Harpoon
		local harpoon = require("harpoon")

		harpoon:setup({
			settings = {
				save_on_toggle = true,
				save_on_ui_close = true,
			},
		})

		-- REQUIRED
		--
		vim.keymap.set("n", "<leader>aa", function()
			harpoon:list():add()
		end)

		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end)

		vim.keymap.set("n", "<leader>as", function()
			harpoon:list():select(1)
		end)
		vim.keymap.set("n", "<leader>ad", function()
			harpoon:list():select(2)
		end)
		vim.keymap.set("n", "<leader>af", function()
			harpoon:list():select(3)
		end)
		vim.keymap.set("n", "<leader>ag", function()
			harpoon:list():select(4)
		end)
		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<C-S-P>", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", "<C-S-N>", function()
			harpoon:list():next()
		end)
	end,
}
