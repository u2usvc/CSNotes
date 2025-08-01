-- vim.keymap.sets are automatically loaded on the VeryLazy event
-- Default vim.keymap.sets that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional vim.keymap.sets here
-- Resize with arrows
vim.keymap.set("n", "<C-M-k>", ":resize -6<CR>")
vim.keymap.set("n", "<C-M-j>", ":resize +6<CR>")
vim.keymap.set("n", "<C-M-h>", ":vertical resize -6<CR>")
vim.keymap.set("n", "<C-M-l>", ":vertical resize +6<CR>")

vim.keymap.set("n", "<C-M-л>", ":resize -6<CR>")
vim.keymap.set("n", "<C-M-о>", ":resize +6<CR>")
vim.keymap.set("n", "<C-M-р>", ":vertical resize -6<CR>")
vim.keymap.set("n", "<C-M-д>", ":vertical resize +6<CR>")

-- Navigate buffers
vim.keymap.set("n", "<S-l>", ":bnext<CR>")
vim.keymap.set("n", "<S-h>", ":bprevious<CR>")

vim.keymap.set("n", "<S-д>", ":bnext<CR>")
vim.keymap.set("n", "<S-р>", ":bprevious<CR>")

-- Move text up and down
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==")
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==")

vim.keymap.set("n", "<A-о>", ":m .+1<CR>==")
vim.keymap.set("n", "<A-л>", ":m .-2<CR>==")

-- Insert --
-- Press jk fast to exit insert mode
vim.keymap.set("i", "jk", "<ESC>")
vim.keymap.set("i", "kj", "<ESC>")

vim.keymap.set("i", "ол", "<ESC>")

-- Visual --
-- Stay in indent mode
vim.keymap.set("v", "<", "<gv^")
vim.keymap.set("v", ">", ">gv^")

-- Move text up and down
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "p", '"_dP')

vim.keymap.set("v", "<A-о>", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "<A-л>", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "з", '"_dP')

-- Visual Block --
-- Move text up and down
vim.keymap.set("x", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("x", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("x", "<A-j>", ":m '>+1<CR>gv=gv")
vim.keymap.set("x", "<A-k>", ":m '<-2<CR>gv=gv")

vim.keymap.set("x", "О", ":m '>+1<CR>gv=gv")
vim.keymap.set("x", "Л", ":m '<-2<CR>gv=gv")
vim.keymap.set("x", "<A-о>", ":m '>+1<CR>gv=gv")
vim.keymap.set("x", "<A-л>", ":m '<-2<CR>gv=gv")

-- -- Visual-line navigation
-- vim.api.nvim_set_vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { noremap = true, expr = true })
-- vim.api.nvim_set_vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { noremap = true, expr = true })
--
-- vim.api.nvim_set_vim.keymap.set("n", "о", "v:count ? 'j' : 'gj'", { noremap = true, expr = true })
-- vim.api.nvim_set_vim.keymap.set("n", "л", "v:count ? 'k' : 'gk'", { noremap = true, expr = true })
-- vim.keymap.set("n", "д", "l")
-- vim.keymap.set("n", "р", "h")

-- Insert newline without leaving normal mode
vim.keymap.set("n", "<M-o>", '@="m`o<C-V><Esc>``"<CR>')
vim.keymap.set("n", "<M-O>", '@="m`O<C-V><Esc>``"<CR>')

vim.keymap.set("n", "<M-щ>", '@="m`o<C-V><Esc>``"<CR>')
vim.keymap.set("n", "<M-Щ>", '@="m`O<C-V><Esc>``"<CR>')

-- Delete without yanking (use "x" for cutting)
vim.keymap.set("n", "dd", '"_dd')
vim.keymap.set("v", "d", '"_d')

vim.keymap.set("n", "вв", '"_dd')
vim.keymap.set("v", "в", '"_d')

-- Move between tabs
vim.keymap.set("n", "<M-h>", "gT")
vim.keymap.set("n", "<M-l>", "gt")

vim.keymap.set("n", "<M-р>", "gT")
vim.keymap.set("n", "<M-д>", "gt")

-- Del emulation in insert mode
vim.keymap.set("i", "<C-l>", "<Del>")

vim.keymap.set("i", "<C-д>", "<Del>")

-- Navigation in insert mode
vim.keymap.set("i", "<C-M-h>", "<Left>")
vim.keymap.set("i", "<C-M-l>", "<Right>")
vim.keymap.set("i", "<C-M-j>", "<Down>")
vim.keymap.set("i", "<C-M-k>", "<Up>")

vim.keymap.set("i", "<C-M-р>", "<Left>")
vim.keymap.set("i", "<C-M-д>", "<Right>")
vim.keymap.set("i", "<C-M-о>", "<Down>")
vim.keymap.set("i", "<C-M-л>", "<Up>")

-- General rus
vim.keymap.set("n", "нн", "yy")

vim.keymap.set("n", "й", "q")
vim.keymap.set("n", "ц", "w")
vim.keymap.set("n", "у", "e")
vim.keymap.set("n", "к", "r")
vim.keymap.set("n", "е", "t")
vim.keymap.set("n", "н", "y")
vim.keymap.set("n", "г", "u")
vim.keymap.set("n", "ш", "i")
vim.keymap.set("n", "щ", "o")
vim.keymap.set("n", "з", "p")
vim.keymap.set("n", "х", "[")
vim.keymap.set("n", "ъ", "]")

vim.keymap.set("n", "ф", "a")
vim.keymap.set("n", "ы", "s")
vim.keymap.set("n", "в", "d")
vim.keymap.set("n", "а", "f")
vim.keymap.set("n", "п", "g")
vim.keymap.set("n", "р", "h")
vim.keymap.set("n", "о", "j")
vim.keymap.set("n", "л", "k")
vim.keymap.set("n", "д", "l")
vim.keymap.set("n", "ж", ";")
vim.keymap.set("n", "э", "'")

vim.keymap.set("n", "я", "z")
vim.keymap.set("n", "ч", "x")
vim.keymap.set("n", "с", "c")
vim.keymap.set("n", "м", "v")
vim.keymap.set("n", "и", "b")
vim.keymap.set("n", "т", "n")
vim.keymap.set("n", "ь", "m")
vim.keymap.set("n", "б", ",")
vim.keymap.set("n", "ю", ".")
vim.keymap.set("n", ".", "/")

vim.keymap.set("n", "ё", "`")

vim.keymap.set("n", "Й", "Q")
vim.keymap.set("n", "Ц", "W")
vim.keymap.set("n", "У", "E")
vim.keymap.set("n", "К", "R")
vim.keymap.set("n", "Е", "T")
vim.keymap.set("n", "Н", "Y")
vim.keymap.set("n", "Г", "U")
vim.keymap.set("n", "Ш", "I")
vim.keymap.set("n", "Щ", "O")
vim.keymap.set("n", "З", "P")
vim.keymap.set("n", "Х", "{")
vim.keymap.set("n", "Ъ", "}")

vim.keymap.set("n", "Ф", "A")
vim.keymap.set("n", "Ы", "S")
vim.keymap.set("n", "В", "D")
vim.keymap.set("n", "А", "F")
vim.keymap.set("n", "П", "G")
vim.keymap.set("n", "Р", "H")
vim.keymap.set("n", "О", "J")
vim.keymap.set("n", "Л", "K")
vim.keymap.set("n", "Д", "L")
vim.keymap.set("n", "Ж", ":")
vim.keymap.set("n", "Э", '"')

vim.keymap.set("n", "Я", "Z")
vim.keymap.set("n", "Ч", "X")
vim.keymap.set("n", "С", "C")
vim.keymap.set("n", "М", "V")
vim.keymap.set("n", "И", "B")
vim.keymap.set("n", "Т", "N")
vim.keymap.set("n", "Ь", "M")
vim.keymap.set("n", "Б", "<")
vim.keymap.set("n", "Ю", ">")
vim.keymap.set("n", ",", "?")

vim.keymap.set("n", "Ё", "~")

vim.keymap.set("v", "й", "q")
vim.keymap.set("v", "ц", "w")
vim.keymap.set("v", "у", "e")
vim.keymap.set("v", "к", "r")
vim.keymap.set("v", "е", "t")
vim.keymap.set("v", "н", "y")
vim.keymap.set("v", "г", "u")
vim.keymap.set("v", "ш", "i")
vim.keymap.set("v", "щ", "o")
vim.keymap.set("v", "з", "p")
vim.keymap.set("v", "х", "[")
vim.keymap.set("v", "ъ", "]")

vim.keymap.set("v", "ф", "a")
vim.keymap.set("v", "ы", "s")
vim.keymap.set("v", "в", "d")
vim.keymap.set("v", "а", "f")
vim.keymap.set("v", "п", "g")
vim.keymap.set("v", "р", "h")
vim.keymap.set("v", "о", "j")
vim.keymap.set("v", "л", "k")
vim.keymap.set("v", "д", "l")
vim.keymap.set("v", "ж", ";")
vim.keymap.set("v", "э", "'")

vim.keymap.set("v", "я", "z")
vim.keymap.set("v", "ч", "x")
vim.keymap.set("v", "с", "c")
vim.keymap.set("v", "м", "v")
vim.keymap.set("v", "и", "b")
vim.keymap.set("v", "т", "v")
vim.keymap.set("v", "ь", "m")
vim.keymap.set("v", "б", ",")
vim.keymap.set("v", "ю", ".")
vim.keymap.set("v", ".", "/")

vim.keymap.set("v", "ё", "`")

vim.keymap.set("v", "Й", "Q")
vim.keymap.set("v", "Ц", "W")
vim.keymap.set("v", "У", "E")
vim.keymap.set("v", "К", "R")
vim.keymap.set("v", "Е", "T")
vim.keymap.set("v", "Н", "Y")
vim.keymap.set("v", "Г", "U")
vim.keymap.set("v", "Ш", "I")
vim.keymap.set("v", "Щ", "O")
vim.keymap.set("v", "З", "P")
vim.keymap.set("v", "Х", "{")
vim.keymap.set("v", "Ъ", "}")

vim.keymap.set("v", "Ф", "A")
vim.keymap.set("v", "Ы", "S")
vim.keymap.set("v", "В", "D")
vim.keymap.set("v", "А", "F")
vim.keymap.set("v", "П", "G")
vim.keymap.set("v", "Р", "H")
vim.keymap.set("v", "О", "J")
vim.keymap.set("v", "Л", "K")
vim.keymap.set("v", "Д", "L")
vim.keymap.set("v", "Ж", ":")
vim.keymap.set("v", "Э", '"')

vim.keymap.set("v", "Я", "Z")
vim.keymap.set("v", "Ч", "X")
vim.keymap.set("v", "С", "C")
vim.keymap.set("v", "М", "V")
vim.keymap.set("v", "И", "B")
vim.keymap.set("v", "Т", "v")
vim.keymap.set("v", "Ь", "M")
vim.keymap.set("v", "Б", "<")
vim.keymap.set("v", "Ю", ">")
vim.keymap.set("v", ",", "?")

vim.keymap.set("v", "Ё", "~")
