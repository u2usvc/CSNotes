return {
  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- We'd like this plugin to load first out of the rest
    config = true, -- This automatically runs `require("luarocks-nvim").setup()`
    commit = "1db9093",
  },

  {
    "nvim-neorg/neorg",
    -- tag = "*",
    commit = "790b044",
    -- commit = "7b3e794aa8722826418501608c8a3ffe4e19ea30",
    -- commit = "0e21ee8df6235511c02bab4a5b391d18e165a58d",
    ft = "norg", -- Specifies functions which load this plugin.
    lazy = ":Neorg sync-parsers", -- Post-update/install hook.
    after = { "nvim-treesitter", "telescope.nvim" }, -- You may want to specify Telescope here as well
    dependencies = { "luarocks.nvim", "nvim-treesitter", "telescope.nvim" },
    config = function()
      require("neorg").setup({
        load = {
          ["core.defaults"] = {}, -- Loads default behaviour
          ["core.autocommands"] = {},
          ["core.concealer"] = {
            config = {
              -- folds = true,
              -- icon_preset = "varied",
              -- init_open_folds = "always",
              icons = {
                -- list = {
                --   icons = { "󰫢", "󰫤", "󰫣", "󰫥", "", "" },
                -- },
                -- heading = {
                --   icons = { "󱗝", "", "", "󰺕", "", "󰺖" },
                -- },
                -- definition = {
                --   single = { icon = "󰷐" },
                --   multi_prefix = { icon = "󰺲" },
                --   multi_suffix = { icon = "󰉺" },
                -- },
                -- ordered = {
                --   -- icons = { "•", "◇", "▪", "-", "→", "⇒" },
                --   level_1 = { icon = "󰬺" },
                --   level_2 = { icon = "󰬻" },
                --   level_3 = { icon = "󰬼" },
                -- },
                -- todo = {
                --   -- done = { icon = "" },
                --   pending = { icon = "󰔟" },
                --   uncertain = { icon = "" },
                --   on_hold = { icon = "" },
                --   cancelled = { icon = "󰜺" },
                --   undone = { icon = "" },
                -- },
                -- delimiter = {
                --   horizontal_line = {
                --     highlight = "@neorg.delimiters.horizontal_line",
                --   },
                -- },
                code_block = {
                  spell_check = false,
                  content_only = true,
                  width = "content",
                  padding = {},
                  conceal = true,
                  nodes = { "ranged_verbatim_tag" },
                  highlight = "CursorColumn",
                  insert_enabled = false,
                },
              },
            },
          }, -- Adds pretty icons to your documents
          ["core.syntax"] = {},
          ["core.export"] = {},
          ["core.highlights"] = {},
          --   -- https://github.com/nvim-neorg/neorg/wiki/Core-Highlights
          --   config = {
          --     highlights = {
          --       links = {
          --         location = {
          --           url = "+@markup.link.url",
          --         },
          --       },
          --       lists = {
          --         unordered = {
          --           prefix = "+@markup.list",
          --         },
          --       },
          --       -- headings = {
          --       --   level_1 = {prefix = "+@constant", title = "+@constant"},
          --       --   level_2 = {prefix = "+@constant", title = "+@constant"},
          --       --   level_3 = {prefix = "+@constant", title = "+@constant"},
          --       -- },
          --     },
          --     dim = {
          --       tags = {
          --         ranged_verbatim = {
          --           code_block = {
          --             affect = "background",
          --             pencentage = 1,
          --             reference = "Normal",
          --           },
          --         },
          --       },
          --     },
          --   },
          -- },
          -- ["core.dirman"] = { -- Manages Neorg workspaces
          --   config = {
          --     workspaces = {
          --       notes = "/home/fuser/main/documents/nvim_vault",
          --     },
          --   },
          -- },
          ["core.esupports.indent"] = {},
        },
      })
    end,
  },
}
