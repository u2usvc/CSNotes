-- reconfigure snacks.nvim to disable smooth scroll
return {
  {
    "snacks.nvim",
    commit = "bc0630e",
    opts = {
      scroll = { enabled = false },
      image = {
        math = {
          latex = {
            font_size = "Large", -- see https://www.sascha-frank.com/latex-font-size.html
            -- for latex documents, the doc packages are included automatically,
            -- but you can add more packages here. Useful for markdown documents.
            packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools", "pgfplots", "circuitikz", "tikz" },
          },
        },
      },
    },
  },
}
