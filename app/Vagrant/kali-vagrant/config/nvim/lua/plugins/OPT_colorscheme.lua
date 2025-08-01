return {
  -- add gruvbox
  {
    "rebelot/kanagawa.nvim", -- current
    commit = "debe91547d7fb1eef34ce26a5106f277fbfdd109",
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-dragon",
    },
  },
}
