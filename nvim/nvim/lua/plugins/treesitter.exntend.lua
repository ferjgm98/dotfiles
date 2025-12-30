return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = { "tree-sitter/tree-sitter-embedded-template" },
  opts = function(_, opts)
    opts.filetype_to_parsername = opts.filetype_to_parsername or {}
    opts.filetype_to_parsername["erb"] = "embedded-template"
    opts.filetype_to_parsername["ejs"] = "embedded-template"
  end,
}
