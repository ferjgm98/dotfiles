-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local map = LazyVim.safe_keymap_set

map("i", "jk", "<esc>", { desc = "Inline Escape" })

map("n", "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", {})
map("n", "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", {})
map("n", "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", {})
map("n", "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", {})

map("n", "<C-M-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<C-M-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<C-M-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<C-M-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<C-M-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<C-M-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
