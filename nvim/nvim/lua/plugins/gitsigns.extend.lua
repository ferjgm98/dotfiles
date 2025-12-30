return {
  "lewis6991/gitsigns.nvim",
  opts = {
    -- Enable inline blame
    current_line_blame = true,
    -- You can tweak or add other options here
  },
  keys = {
    -- Add a keymap to preview the current hunk
    {
      "<leader>ghp",
      function()
        require("gitsigns").preview_hunk()
      end,
      desc = "preview git hunk",
    },
    {
      "<leader>ghb",
      function()
        require("gitsigns").toggle_current_line_blame()
      end,
      desc = "Toggle inline blame",
    },
  },
}
