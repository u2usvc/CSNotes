return {
  {
    "saghen/blink.cmp",
    optional = true,
    -- dependencies = { "supermaven-nvim", "saghen/blink.compat" },
    opts = {
      -- sources = {
      --   compat = { "supermaven" },
      --   providers = {
      --     supermaven = {
      --       kind = "Supermaven",
      --       score_offset = 100,
      --       async = true,
      --     },
      --   },
      -- },

      -- disable ghost text to prevent it from hiding supermaven completions
      completion = {
        ghost_text = { enabled = false },
      },

      keymap = {
        preset = "default",
        ["<c-x>"] = { "show", "show_documentation", "hide_documentation" },
        ["<c-e>"] = { "cancel", "fallback" },
        ["<tab>"] = {},
        ["<c-y>"] = { "select_and_accept" },
        ["<c-k>"] = { "select_prev", "fallback" },
        ["<up>"] = { "select_prev", "fallback" },
        ["<c-j>"] = { "select_next", "fallback" },
        ["<down>"] = { "select_next", "fallback" },
      },
    },
  },
}
