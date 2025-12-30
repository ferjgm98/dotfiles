-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Guard for older Neovim versions that don't have this API yet
if vim.lsp and vim.lsp.inline_completion and vim.lsp.inline_completion.enable then
  vim.lsp.inline_completion.enable()
end
