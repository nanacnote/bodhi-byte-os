---------------------------------------------------------------
--- => General
---------------------------------------------------------------
-- disable language provider support
-- (lua and vimscript plugins only)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python_provider = 0
vim.g.loaded_python3_provider = 0

-- Set utf8 as standard encoding and en_US as the standard language
vim.opt.encoding = 'utf-8'
vim.opt.langmenu = 'en'

-- Disable Vi backwards compatibility
vim.opt.compatible = false

-- Setting dark mode
vim.opt.background = 'dark'

-- Add true color support
vim.opt.termguicolors = true

-- Allows switching buffers without having to write/save
vim.opt.hidden = true

-- Undo even after closing buffer
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand('~/.config/nvim/tmp/undodir')

-- Add line numbers
vim.opt.number = true

-- Make line numbers relative
vim.opt.relativenumber = true

-- Sets how many lines of history VIM has to remember
vim.opt.history = 500

-- Set to auto read when a file is changed from the outside
vim.opt.autoread = true

-- Set 7 lines to the cursor - when moving vertically using j/k
vim.opt.scrolloff = 7

-- Always show current position
vim.opt.ruler = true

-- Height of the command bar
vim.opt.cmdheight = 1

-- A buffer becomes hidden when it is abandoned
vim.opt.hidden = true

-- Configure backspace so it acts as it should act
vim.opt.backspace = { 'eol', 'start', 'indent' }

-- Go to next/previous line when using left or right arrow
vim.opt.whichwrap:append('<,>')

-- Ignore case when searching
vim.opt.ignorecase = true

-- When searching try to be smart about cases
vim.opt.smartcase = true

-- Highlight search results
vim.opt.hlsearch = true

-- Makes search act like search in modern browsers
vim.opt.incsearch = true

-- Don't redraw while executing macros (good performance config)
vim.opt.lazyredraw = true

-- For regular expressions turn magic on
vim.opt.magic = true

-- Show matching brackets when text indicator is over them
vim.opt.showmatch = true

-- How many tenths of a second to blink when matching brackets
vim.opt.matchtime = 2

-- No annoying sound on errors
vim.opt.errorbells = false
vim.opt.visualbell = false
vim.opt.belloff = 'all'

-- Add a bit extra margin to the left
vim.opt.foldcolumn = '2'

-- Turn backup off, since most stuff is in SVN, git etc. anyway...
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Use spaces instead of tabs
vim.opt.expandtab = true

-- Be smart when using tabs
vim.opt.smarttab = true

-- 1 tab == 4 spaces
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Linebreak on 500 characters
vim.opt.linebreak = true
vim.opt.textwidth = 500

-- Auto indent
vim.opt.autoindent = true

-- Smart indent
vim.opt.smartindent = true

-- Wrap lines
vim.opt.wrap = true

-- Use Unix as the standard file type
vim.opt.fileformats = { 'unix', 'dos', 'mac' }

-- Always show the status line
vim.opt.laststatus = 2

-- Specify the behavior when switching between buffers
vim.opt.switchbuf = { 'useopen', 'usetab', 'newtab' }

-- Show tab line menu
vim.opt.showtabline = 2

-- Command mode autocomplete
vim.opt.wildmenu = true

-- Highlight current line
vim.opt.cursorline = true

-- Wait time before swapfile writes to disk
vim.opt.updatetime = 300

-- Don't pass messages to ins-completion-menu
vim.opt.shortmess:append('c')

-- Replaces line number with line status signs like errors
vim.opt.signcolumn = 'auto'

-- Add word suggestion to autocomplete
vim.opt.complete:append('kspell')

-- Add spell check
vim.opt.spell = true
vim.opt.spelllang = 'en'

-- Points to custom word dictionary file
vim.opt.spellfile = vim.fn.expand('~/.vim/spell/en.utf-8.add')

-- Ignore compiled files
vim.opt.wildignore = '*.o,*~,*.pyc,*/.git/*,*/.hg/*,*/.svn/*,*/.DS_Store'

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1


---------------------------------------------------------------
--- => Plugins
---------------------------------------------------------------
local plugins = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-tree/nvim-web-devicons' },
    { 'nvim-lualine/lualine.nvim' },
    { 'nvim-telescope/telescope.nvim' },
    { 'nvim-treesitter/nvim-treesitter' },
    { 'nvim-tree/nvim-tree.lua' },
    { 'ellisonleao/gruvbox.nvim' },
    { 'lewis6991/gitsigns.nvim' },
    { 'windwp/nvim-autopairs' },
    { 'akinsho/toggleterm.nvim' },
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-buffer' },
    { 'L3MON4D3/LuaSnip' },
}

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
require('lazy').setup(plugins)


---------------------------------------------------------------
--- => Initialisers
---------------------------------------------------------------
vim.cmd([[colorscheme gruvbox]])
require('lualine').setup { options = { theme = 'gruvbox' } }
require('telescope').setup()
require('nvim-treesitter').setup()
require('nvim-tree').setup()
require('gitsigns').setup()
require('nvim-autopairs').setup()
require('toggleterm').setup()


---------------------------------------------------------------
--- => Functions
---------------------------------------------------------------
-- Switch to the next window in a circular manner
function _G._cycle_windows()
    local current_win = vim.api.nvim_get_current_win()
    local windows = vim.api.nvim_list_wins()

    for i, win in ipairs(windows) do
        if win == current_win then
            local next_win = windows[(i % #windows) + 1]
            vim.api.nvim_set_current_win(next_win)
            break
        end
    end
end

-- display a floating terminal
function _G._toggle_float_term()
    local Terminal = require('toggleterm.terminal').Terminal
    local lazygit  = Terminal:new({
        hidden = true,
        count = 0,
        direction = "float",
        float_opts = {
            border = "curved",
        },
    })
    lazygit:toggle()
end

-- start lazygit as a floating terminal
function _G._toggle_lazygit_term()
    local Terminal = require('toggleterm.terminal').Terminal
    local lazygit  = Terminal:new({
        cmd = "lazygit",
        hidden = true,
        count = 0,
        direction = "float",
        float_opts = {
            border = "curved",
        },
    })
    lazygit:toggle()
end

---------------------------------------------------------------
--- => Keymaps
---------------------------------------------------------------
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Leader key remap to space
keymap('', '<Space>', '<Nop>', opts)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- INSERT MODE
-- Exit insert mode
keymap('i', 'jj', '<ESC>', opts)

-- TERMINAL MODE
-- Exit terminal mode
keymap('t', '<ESC><ESC>', [[<C-\><C-n>]], opts)

-- Windows navigation (terminal mode)
-- Redundant since you can hit esc and use normal mode keybindings
-- keymap('t', '<C-h>', [[<C-\><C-n><C-w>h]], opts)
-- keymap('t', '<C-j>', [[<C-\><C-n><C-w>j]], opts)
-- keymap('t', '<C-k>', [[<C-\><C-n><C-w>k]], opts)
-- keymap('t', '<C-l>', [[<C-\><C-n><C-w>l]], opts)

-- NORMAL MODE
-- Window split
keymap('n', '<leader>sh', ':split<CR>', opts)
keymap('n', '<leader>sv', ':vsplit<CR>', opts)

--Window close
keymap('n', '<leader>c', ':close<CR>', opts)

-- Window navigation
keymap('n', '<C-h>', '<C-w>h', opts)
keymap('n', '<C-j>', '<C-w>j', opts)
keymap('n', '<C-k>', '<C-w>k', opts)
keymap('n', '<C-l>', '<C-w>l', opts)
keymap('n', '<C-n>', '<cmd>lua _cycle_windows()<CR>', opts)

-- Resize window with arrows
keymap('n', '<C-Up>', ':resize -2<CR>', opts)
keymap('n', '<C-Down>', ':resize +2<CR>', opts)
keymap('n', '<C-Left>', ':vertical resize -2<CR>', opts)
keymap('n', '<C-Right>', ':vertical resize +2<CR>', opts)

-- Buffer navigation
keymap('n', '<S-l>', ':bnext<CR>', opts)
keymap('n', '<S-h>', ':bprevious<CR>', opts)

-- Buffer write (save)
keymap('n', '<leader>w', ':w<CR>', opts)

-- Line move up and down
keymap('n', '<A-j>', ':m .+1<CR>==', opts)
keymap('n', '<A-k>', ':m .-2<CR>==', opts)

-- Toggleterm keybindings (use 2ToggleTerm for added terms)
keymap('n', '<leader>tt', ':ToggleTerm hide_numbers=true<CR>', opts)
keymap('n', '<leader>th', ':ToggleTerm direction=horizontal hide_numbers=true<CR>', opts)
keymap('n', '<leader>tv', ':ToggleTerm direction=vertical hide_numbers=true<CR>', opts)
keymap('n', '<leader>tf', '<cmd>lua _toggle_float_term()<CR>', opts)
keymap('n', '<leader>tg', '<cmd>lua _toggle_lazygit_term()<CR>', opts)

-- Nvimtree keybindings
keymap('n', '<leader>et', ':NvimTreeToggle<CR>', opts)
keymap('n', '<leader>er', ':NvimTreeRefresh<CR>', opts)
keymap('n', '<leader>ef', ':NvimTreeFindFile<CR>', opts)

-- Telescope keybindings
local builtin = require('telescope.builtin')
keymap('n', '<leader>ff', builtin.find_files, opts)
keymap('n', '<leader>fg', builtin.live_grep, opts)
keymap('n', '<leader>fb', builtin.buffers, opts)
keymap('n', '<leader>fh', builtin.help_tags, opts)
keymap('n', '<leader>fa', '<cmd>lua require("telescope.builtin").find_files({hidden=true})<CR>', opts)


---------------------------------------------------------------
--- => Automations
---------------------------------------------------------------
-- Update buffer when changes are made from outside Neovim
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter' }, {
    pattern = '*',
    command = 'checktime'
})

-- Return to last edit position when opening files
vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*',
    callback = function()
        local line = vim.fn.line
        if line('\'"') > 1 and line('\'"') <= line('$') then
            vim.cmd('normal! g`"')
        end
    end
})

-- Save buffer on buffer switch
vim.api.nvim_create_autocmd('BufLeave', {
    pattern = '*',
    command = 'silent! update'
})


---------------------------------------------------------------
--- => Language Server
---------------------------------------------------------------
-- Vim diagnostics
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>')
vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<cr>')
vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<cr>')

vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(event)
        local lsp_opts = { buffer = event.buf }
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', lsp_opts)
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', lsp_opts)
        vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', lsp_opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', lsp_opts)
        vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', lsp_opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', lsp_opts)
        vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', lsp_opts)
        vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', lsp_opts)
        vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', lsp_opts)
        vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', lsp_opts)
    end
})

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
require('mason').setup({})
require('mason-lspconfig').setup({
    ensure_installed = {
        'lua_ls',
        'tsserver',
        'pyright',
        'html',
        'cssls',
        'jsonls',
        'clangd',
        'jdtls',
        'yamlls',
        'bashls',
        'dockerls',
        -- 'gopls',
        -- 'rust_analyzer',
        -- 'solargraph',
        -- 'intelephense',
        -- 'hls',
    },
    handlers = {
        function(server)
            require('lspconfig')[server].setup({ capabilities = lsp_capabilities })
        end,
    },
})

local cmp = require('cmp')
cmp.setup({
    sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'buffer' },
    },
    mapping = cmp.mapping.preset.insert({
        ['<CR>'] = cmp.mapping.confirm({ select = false }), -- Enter key confirms completion item
        ['<C-Space>'] = cmp.mapping.complete(),             -- Ctrl + space triggers completion menu
        ['<Tab>'] = cmp.mapping(function(fallback)
             if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end),
        ['<ESC>'] =  cmp.mapping(function(fallback)
             if cmp.visible() then
                cmp.close()
            else
                fallback()
            end
        end),
    }),
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
})

require 'lspconfig'.lua_ls.setup { settings = { Lua = { diagnostics = { globals = { 'vim' } } } } }
