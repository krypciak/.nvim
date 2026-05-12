vim.o.relativenumber = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.mouse = 'a'
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.wo.number = true

vim.opt.showmode = false -- Don't show the mode, since it's already in the status line
vim.opt.breakindent = true -- Make wrapped lines keep the same indent
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 700
vim.opt.redrawtime = 10000
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.cursorline = true -- Show which line your cursor is on
vim.opt.ff = 'unix'
vim.o.cursorline = true
vim.o.signcolumn = 'auto' -- Sign column is the column on the left for errors
vim.o.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.

vim.o.list = true -- Show whitespace charactes if they are at the end of a line
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.api.nvim_set_keymap('n', '<Space>', '', {})
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

local function is_big_file(bufnr)
    return vim.api.nvim_buf_line_count(bufnr) > 20000 or #vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] > 5000
end

-- folds
vim.o.foldenable = true
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.opt.foldcolumn = '0'
vim.o.foldtext = ''
vim.opt.fillchars:append { fold = ' ' }

vim.opt.viewoptions = { 'folds', 'cursor' }
vim.api.nvim_create_augroup('remember_folds', { clear = true })
vim.api.nvim_create_autocmd('BufWinLeave', {
    group = 'remember_folds',
    callback = function()
        if vim.bo.filetype == 'help' then return end
        vim.cmd('silent! mkview')
    end,
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    group = 'remember_folds',
    callback = function(args)
        if vim.bo.filetype == 'help' then return end
        if is_big_file(args.buf) then
            vim.defer_fn(function()
                vim.schedule(function() vim.cmd('silent! loadview') end)
            end, 1500)
        else
            vim.cmd('silent! loadview')
        end
    end,
})

-- undo
vim.o.undofile = true
vim.o.undodir = vim.fn.expand('$HOME/.cache/nvim/undo/')

vim.api.nvim_set_hl(0, 'Folded', { ctermbg = 237 })
vim.api.nvim_set_hl(0, 'Pmenu', { ctermbg = 233, ctermfg = 254 })
vim.api.nvim_set_hl(0, 'PmenuSel', { ctermbg = 238, ctermfg = 255 })
vim.api.nvim_set_hl(0, 'CursorLine', { ctermbg = 235 })
vim.api.nvim_create_autocmd('WinEnter', {
    callback = function() vim.opt_local.cursorline = true end,
})
vim.api.nvim_create_autocmd('WinLeave', {
    callback = function() vim.opt_local.cursorline = false end,
})

-- Return to last edit position when opening files
vim.cmd([[
    autocmd BufReadPost *
         \ if line("'\"") > 0 && line("'\"") <= line("$") |
         \   exe "normal! g`\"" |
         \ endif
]])

vim.cmd([[
" # Function to permanently delete views created by 'mkview'
function! MyDeleteView()
    let path = fnamemodify(bufname('%'),':p')
    " vim's odd =~ escaping for /
    let path = substitute(path, '=', '==', 'g')
    if empty($HOME)
    else
        let path = substitute(path, '^'.$HOME, '\~', '')
    endif
    let path = substitute(path, '/', '=+', 'g') . '='
    " view directory
    let path = &viewdir.'/'.path
    call delete(path)
    echo "Deleted: ".path
endfunction

" # Command Delview (and it's abbreviation 'delview')
command Delview call MyDeleteView()
" Lower-case user commands: http://vim.wikia.com/wiki/Replace_a_builtin_command_using_cabbrev
cabbrev delview <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? 'Delview' : 'delview')<CR>
]])

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.hl.on_yank() end,
})

-- keybindings
-- d stands for delete not cut
vim.keymap.set('n', 'x', '"_x')
vim.keymap.set('n', 'X', '"_X')
vim.keymap.set('n', 'd', '"_d')
vim.keymap.set('n', 'D', '"_D')
vim.keymap.set('v', 'd', '"_d')
vim.keymap.set('n', '<leader>d', '"+d')
vim.keymap.set('n', '<leader>D', '"+D')
vim.keymap.set('v', '<leader>d', '"+d')
vim.keymap.set('v', 'p', 'pgvy')

vim.keymap.set('', '<leader>q', '<cmd>q<CR>')
vim.keymap.set('', '<leader>w', '<cmd>w<CR>')
vim.keymap.set('', '<leader>r', '<cmd>q!<CR>')
vim.keymap.set('', '<leader>e', '<cmd>wq<CR>')

vim.keymap.set('v', ';;', '<esc>')
vim.keymap.set('i', ';l', '<esc>')
vim.keymap.set('t', ';l', '<C-\\><C-n>')

vim.keymap.set('n', 'zr', 'zR')
vim.keymap.set('n', 'zm', 'zM')

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('t', '<C-h>', '<cmd>wincmd h<CR>')
vim.keymap.set('t', '<C-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('t', '<C-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('t', '<C-l>', '<C-l><cmd>wincmd l<CR>')

vim.keymap.set('n', '<leader>tw', '<cmd>set wrap!<CR>', { silent = true })
vim.keymap.set('n', '<leader>k', '<cmd>nohlsearch<CR>', { silent = true })
vim.keymap.set('', '<leader>z', '<cmd>%y<CR>')

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzvzz')
vim.keymap.set('n', 'N', 'Nzzzvzz')
vim.keymap.set('n', '<c-o>', '<c-o>zz')
vim.keymap.set('n', '<c-i>', '<c-i>zz')

vim.keymap.set('n', '[s', '[szz')
vim.keymap.set('n', ']s', ']szz')

vim.keymap.set('t', '<c-q>', '<cmd><cmd>q!<CR>')

-- spelling
vim.opt.spelllang = 'en_us'
vim.opt.spell = false
vim.keymap.set('', '<leader>p', '<cmd>setlocal spell!<CR>')

vim.diagnostic.config {
    update_in_insert = false,
    -- severity_sort = true,
    float = { border = 'rounded', source = 'if_many' },
    -- underline = { severity = { min = vim.diagnostic.severity.WARN } },

    -- Can switch between these as you prefer
    virtual_text = true, -- Text shows up at the end of the line
    virtual_lines = false, -- Text shows up underneath the line, with virtual lines
}

-- plugins
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

local function get_git_toplevel()
    local obj = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait()
    if string.len(obj.stderr) > 5 then return nil end
    return string.sub(obj.stdout, 0, string.len(obj.stdout) - 1)
end

require('lazy').setup({
    'itchyny/lightline.vim',
    { -- telescope
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-telescope/telescope-fzf-native.nvim', 'debugloop/telescope-undo.nvim' },
        lazy = false,
        opts = {
            extensions = {
                undo = {},
            },
        },
        setup = function(_, opts)
            local telescope = require('telescope')
            telescope.load_extension('fzf')
            telescope.load_extension('undo')
            telescope.setup(opts)
        end,
        keys = {
            {
                '<leader>fa',
                function()
                    if get_git_toplevel() then
                        require('telescope.builtin').git_files { show_untracked = true }
                    else
                        require('telescope.builtin').find_files {}
                    end
                end,
            },
            { '<leader>fA', '<cmd>Telescope find_files no_ignore=true no_ignore_parent=true<CR>' },
            {
                '<leader>fs',
                function() require('telescope.builtin').live_grep { cwd = get_git_toplevel() } end,
            },
            { '<leader>fd', '<cmd>Telescope current_buffer_fuzzy_find<CR>' },
            { '<leader>fg', '<cmd>Telescope git_bcommits<CR>' },
            {
                '<leader>m',
                function()
                    require('telescope.builtin').find_files {
                        default_text = vim.fn.getreg('+'),
                    }
                end,
            },
            { '<leader>fu', '<cmd>Telescope undo<CR>' },

            -- {
            --     '<leader>fe',
            --     function()
            --         local actions = require('telescope.actions')
            --         local action_state = require('telescope.actions.state')
            --         local finders = require('telescope.finders')
            --         local pickers = require('telescope.pickers')
            --         local sorters = require('telescope.sorters')
            --
            --         local lines =
            --             vim.split(vim.fn.system("cliphist list | awk '{print substr($0, index($0, $2))}'"), '\n')
            --         local opts = {
            --             prompt_title = 'Cliphist',
            --             finder = finders.new_table({
            --                 results = lines,
            --             }),
            --             sorter = sorters.get_generic_fuzzy_sorter(),
            --             attach_mappings = function(_, map)
            --                 function os.capture(cmd)
            --                     local f = assert(io.popen(cmd, 'r'))
            --                     local s = assert(f:read('*a'))
            --                     f:close()
            --                     return s
            --                 end
            --                 local function decode_and_paste(prompt_bufnr)
            --                     local selection = action_state.get_selected_entry(prompt_bufnr)
            --                     actions.close(prompt_bufnr)
            --                     if selection then vim.fn.setreg('+', selection.value) end
            --                 end
            --                 map('i', '<CR>', decode_and_paste)
            --                 map('n', '<CR>', decode_and_paste)
            --                 return true
            --             end,
            --         }
            --
            --         pickers.new(opts, {}):find()
            --     end,
            -- },
        },
    },
    { -- telescope-fzf-native
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        lazy = true,
    },
    { -- treesitter
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        branch = 'main',
        build = ':TSUpdate',
        config = function()
            require('nvim-treesitter').install { 'lua', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

            ---@param buf integer
            ---@param language string
            local function treesitter_try_attach(buf, language)
                -- check if parser exists and load it
                if not vim.treesitter.language.add(language) then return end
                -- enables syntax highlighting and other treesitter features
                vim.treesitter.start(buf, language)

                -- enables treesitter based folds
                -- for more info on folds see `:help folds`
                vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                vim.wo.foldmethod = 'expr'

                -- check if treesitter indentation is available for this language, and if so enable it
                -- in case there is no indent query, the indentexpr will fallback to the vim's built in one
                local has_indent_query = vim.treesitter.query.get(language, 'indent') ~= nil

                -- enables treesitter based indentation
                if has_indent_query then vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
            end

            local available_parsers = require('nvim-treesitter').get_available()
            vim.api.nvim_create_autocmd('FileType', {
                callback = function(args)
                    local buf, filetype = args.buf, args.match

                    local language = vim.treesitter.language.get_lang(filetype)
                    if not language then return end

                    local installed_parsers = require('nvim-treesitter').get_installed('parsers')

                    if vim.tbl_contains(installed_parsers, language) then
                        -- enable the parser if it is installed
                        treesitter_try_attach(buf, language)
                    elseif vim.tbl_contains(available_parsers, language) then
                        -- if a parser is available in `nvim-treesitter` auto install it, and enable it after the installation is done
                        require('nvim-treesitter')
                            .install(language)
                            :await(function() treesitter_try_attach(buf, language) end)
                    else
                        -- try to enable treesitter features in case the parser exists but is not available from `nvim-treesitter`
                        treesitter_try_attach(buf, language)
                    end
                end,
            })
        end,
    },
    { 'tpope/vim-surround' },
    { 'NMAC427/guess-indent.nvim', opts = {} },
    { -- origami
        'chrisgrieser/nvim-origami',
        event = 'VeryLazy',
        opts = {
            useLspFoldsWithTreesitterFallback = {
                enabled = false,
            },
            foldtext = {
                padding = {
                    width = 1,
                },
                lineCount = {
                    template = '󰁂 %d',
                    hlgroup = 'Title',
                },
            },
            foldKeymaps = {
                setup = false,
            },
        },
        init = function() end,
    },
    { 'nvim-tree/nvim-web-devicons', lazy = true },
    { -- conform
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                javascript = { 'prettier' },
                typescript = { 'prettier' },
                html = { 'prettier' },
                css = { 'prettier' },
                json = { 'prettier' },
                sh = { 'shfmt' },
                python = { 'black' },
                kotlin = { 'ktfmt' },
                zig = { 'zigfmt' },
            },
            notify_on_error = true,
            ignore_errors = false,
            formatters = {
                shfmt = {
                    command = 'shfmt',
                    prepend_args = { '-i', '4' },
                },
                jsonprettierd = {
                    stdin = true,
                    inherit = false,
                    command = 'prettierd',
                    args = { '--parser=json', '--stdin-filepath', '$FILENAME' },
                },
            },
        },
        keys = {
            {
                '<leader>gf',
                function() Format() end,
                mode = { 'n' },
                desc = 'Format the current buffer',
            },
        },
    },
    { -- nvim-lspconfig
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            { 'williamboman/mason.nvim', config = true },
            'williamboman/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',

            -- Useful status updates for LSP.
            { 'j-hui/fidget.nvim', opts = {} },
        },
        config = function()
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
                callback = function(event)
                    local map = function(keys, func, desc)
                        vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                    end

                    -- Jump to the definition of the word under your cursor.
                    --  This is where a variable was first declared, or where a function is defined, etc.
                    --  To jump back, press <C-t>.
                    map('<leader>gd', require('telescope.builtin').lsp_definitions, 'goto definition')
                    map(
                        '<leader>gD',
                        function() require('telescope.builtin').lsp_definitions { jump_type = 'never' } end,
                        'goto definition'
                    )

                    map('<leader>gs', require('telescope.builtin').lsp_references, 'goto references')

                    -- Jump to the implementation of the word under your cursor.
                    --  Useful when your language has ways of declaring types without an actual implementation.
                    --  todo
                    -- map('<leader>gD', require('telescope.builtin').lsp_implementations, 'goto implementation')

                    -- Jump to the type of the word under your cursor.
                    --  Useful when you're not sure what type a variable is and you want to see
                    --  the definition of its *type*, not where it was *defined*.
                    --  todo
                    -- map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

                    -- Fuzzy find all the symbols in your current document.
                    --  Symbols are things like variables, functions, types, etc.
                    --  todo
                    -- map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

                    -- Fuzzy find all the symbols in your current workspace.
                    --  Similar to document symbols, except searches over your entire project.
                    --  todo
                    -- map(
                    --     '<leader>ws',
                    --     require('telescope.builtin').lsp_dynamic_workspace_symbols,
                    --     '[W]orkspace [S]ymbols'
                    -- )

                    map('<leader>s', vim.lsp.buf.rename, 'rename')
                    map('<leader>ca', vim.lsp.buf.code_action, 'code action')
                    map('K', vim.lsp.buf.hover, 'Hover Documentation')
                    -- map('<leader>gD', vim.lsp.buf.declaration, 'goto declaration')

                    -- The following two autocommands are used to highlight references of the
                    -- word under your cursor when your cursor rests there for a little while.
                    --    See `:help CursorHold` for information about when this is executed
                    --
                    -- When you move your cursor, the highlights will be cleared (the second autocommand).
                    -- todo
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    -- if client and client.server_capabilities.documentHighlightProvider then
                    --     local highlight_augroup =
                    --         vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
                    --     vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                    --         buffer = event.buf,
                    --         group = highlight_augroup,
                    --         callback = vim.lsp.buf.document_highlight,
                    --     })
                    --
                    --     vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                    --         buffer = event.buf,
                    --         group = highlight_augroup,
                    --         callback = vim.lsp.buf.clear_references,
                    --     })
                    --
                    --     vim.api.nvim_create_autocmd('LspDetach', {
                    --         group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                    --         callback = function(event2)
                    --             vim.lsp.buf.clear_references()
                    --             vim.api.nvim_clear_autocmds({ group = 'kickstart-lsp-highlight', buffer = event2.buf })
                    --         end,
                    --     })
                    -- end

                    -- The following autocommand is used to enable inlay hints in your
                    -- code, if the language server you are using supports them
                    --
                    -- This may be unwanted, since they displace some of your code
                    if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
                        map(
                            '<leader>th',
                            function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end,
                            'Toggle Inlay Hints'
                        )
                    end

                    -- Disable java lsp (jdtls) from providing its own (worse in my opinion) sytnax highlighting
                    if client and client.name == 'jdtls' then
                        client.server_capabilities.semanticTokensProvider = nil
                    end
                end,
            })

            -- local mason_registry = require('mason-registry')
            -- local vue_language_server_path = mason_registry.get_package('vue-language-server'):get_install_path()
            --     .. '/node_modules/@vue/language-server'

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            -- capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

            -- Enable the following language servers
            --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
            --
            --  Add any additional override configuration in the following tables. Available keys are:
            --  - cmd (table): Override the default command used to start the server
            --  - filetypes (table): Override the default list of associated filetypes for the server
            --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
            --  - settings (table): Override the default settings passed when initializing the server.
            --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = 'Replace',
                            },
                        },
                    },
                },
                jsonls = {
                    settings = {
                        json = {
                            schemas = require('schemastore').json.schemas(),
                            validate = { enable = true },
                        },
                    },
                },
                pylsp = {
                    settings = {
                        pylsp = {
                            plugins = {
                                pycodestyle = {
                                    ignore = { 'E261', 'E303', 'E302', 'E305' },
                                    maxLineLength = 200,
                                },
                            },
                        },
                    },
                },
                -- hls = {
                --     filetypes = { 'haskell', 'lhaskell', 'cabal' },
                -- },
                zls = {},
                jdtls = {},
                yamlls = {},
                bashls = {
                    cmd = { 'bash-language-server', 'start' },
                    filetypes = { 'bash', 'sh' },
                },
                julials = {},
                csharp_ls = {},
                emmet_language_server = {},
            }
            require('mason').setup()

            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                'stylua',
            })
            require('mason-tool-installer').setup { ensure_installed = ensure_installed }

            for server_name, server in pairs(servers) do
                server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                vim.lsp.enable(server_name)
                vim.lsp.config(server_name, server)
            end

            require('mason-lspconfig').setup {
                ensure_installed = {},
                automatic_enable = {},
                automatic_installation = true,
            }
        end,
    },
    { -- nvim-lint
        'mfussenegger/nvim-lint',
        lazy = true,
        enabled = false,
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            vim.env.ESLINT_D_PPID = vim.fn.getpid()
            vim.env.ESLINT_D_MISS = 'ignore'
            local lint = require('lint')

            lint.linters_by_ft = {
                javascript = { 'eslint_d' },
                typescript = { 'eslint_d' },
                -- python = { 'pylint' },
            }

            local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })

            vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
                group = lint_augroup,
                callback = function() lint.try_lint() end,
            })
        end,
    },
    { -- blink.cmp
        'saghen/blink.cmp',
        event = 'VimEnter',
        version = '1.*',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                version = '2.*',
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then return end
                    return 'make install_jsregexp'
                end)(),
                dependencies = {},
                opts = {},
            },
        },
        opts = {
            keymap = {
                -- 'default' (recommended) for mappings similar to built-in completions
                --   <c-y> to accept ([y]es) the completion.
                --    This will auto-import if your LSP supports it.
                --    This will expand snippets if the LSP sent a snippet.
                -- 'super-tab' for tab to accept
                -- 'enter' for enter to accept
                -- 'none' for no mappings
                --
                -- For an understanding of why the 'default' preset is recommended,
                -- you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                --
                -- All presets have the following mappings:
                -- <tab>/<s-tab>: move to right/left of your snippet expansion
                -- <c-space>: Open menu or open docs if already open
                -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                -- <c-e>: Hide menu
                -- <c-k>: Toggle signature help
                --
                -- See :h blink-cmp-config-keymap for defining your own keymap
                preset = 'default',

                ['<CR>'] = { 'accept', 'fallback' },
                ['<Tab>'] = { 'select_next', 'fallback' },
                ['<C-Tab>'] = { 'select_prev', 'fallback' },

                -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
            },

            appearance = {
                -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'mono',
            },

            completion = {
                -- By default, you may press `<c-space>` to show the documentation.
                -- Optionally, set `auto_show = true` to show the documentation after a delay.
                documentation = { auto_show = false, auto_show_delay_ms = 500 },

                accept = { auto_brackets = { enabled = true } },
            },

            sources = {
                default = { 'lazydev', 'lsp', 'path', 'snippets' },

                providers = {
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        -- make lazydev completions top priority (see `:h blink.cmp`)
                        score_offset = 100,
                    },
                },
            },

            snippets = { preset = 'luasnip' },

            -- See :h blink-cmp-config-fuzzy for more information
            fuzzy = { implementation = 'prefer_rust_with_warning' },

            -- Shows a signature help window while you type arguments for a function
            -- signature = { enabled = true },
        },
    },
    { -- autopairs
        'windwp/nvim-autopairs',
        dependencies = { 'hrsh7th/nvim-cmp' },
        event = 'InsertEnter',
        lazy = false,
        priority = 1000,
        opts = {
            map_cr = true,
        },
        config = function(_, opts)
            local autopairs = require('nvim-autopairs')
            autopairs.setup(opts)
        end,
    },

    { -- lazygit
        'kdheepak/lazygit.nvim',
        cmd = {
            'LazyGit',
            'LazyGitConfig',
            'LazyGitCurrentFile',
            'LazyGitFilter',
            'LazyGitFilterCurrentFile',
        },
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { '<leader>lg', '<cmd>LazyGit<CR>', desc = 'LazyGit' },
        },
    },
    { -- toggleterm
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {},
        keys = {
            { '<leader>lt', '<cmd>ToggleTerm direction=horizontal size=15<CR>' },
            { '<leader>ly', '<cmd>ToggleTerm direction=vertical size=80<CR>' },
        },
    },
    { -- bamboo
        'ribru17/bamboo.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            colors = {
                black = '#111210',
                bg0 = '#1d1f21', -- '#252623',
                bg1 = '#303336',
                bg2 = '#303336',
                bg3 = '#303336',
                bg_d = '#232627', -- '#1c1e1b',
                bg_blue = '#68aee8',
                bg_yellow = '#e2c792',
                fg = '#fcfcfc', -- '#f1e9d2',
                purple = '#9b59b6', -- '#aaaaff',
                bright_purple = '#df73ff',
                green = '#11d116', -- '#8fb573',
                orange = '#ff9966',
                blue = '#1d99f3', -- '#57a5e5',
                yellow = '#fdbc4b', -- '#dbb651',
                cyan = '#1abc9c', -- '#70c2be',
                red = '#ed1515', -- '#e75a7c',
                coral = '#f08080',
                grey = '#7f8c8d', -- '#5b5e5a',
                light_grey = '#838781',
                diff_add = '#40531b',
                diff_delete = '#893f45',
                diff_change = '#2a3a57',
                diff_text = '#3a4a67',
            },
        },
        config = function(_, opts)
            require('bamboo').setup(opts)
            require('bamboo').load()
        end,
    },
    { -- rainbow-delimiters
        'hiphish/rainbow-delimiters.nvim',
        config = function()
            require('rainbow-delimiters.setup').setup {
                condition = function(bufnr) return not is_big_file(bufnr) end,
            }
        end,
    },
    { -- todo-comments
        'folke/todo-comments.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = { signs = false },
        event = 'VimEnter',
        keys = {
            { ']t', function() require('todo-comments').jump_next() end, { desc = 'Next todo comment' } },
            { '[t', function() require('todo-comments').jump_prev() end, { desc = 'Previous todo comment' } },
        },
    },
    { -- markdown-preview
        'iamcco/markdown-preview.nvim',
        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },
        build = function() vim.fn['mkdp#util#install']() end,
    },
    { -- difbuf
        'elihunter173/dirbuf.nvim',
        opts = {},
        keys = {
            { '<leader>i', '<cmd>Dirbuf<CR>' },
        },
    },
    {
        'm4xshen/hardtime.nvim',
        lazy = false,
        dependencies = { 'MunifTanjim/nui.nvim' },
        opts = {},
    },
    -- language specific
    { -- lazydev.nvim
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
            },
        },
    },
    { -- typescript-tools
        'notomo/typescript-tools.nvim',
        dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
        opts = {},
    },
    { -- SchemaStore
        'b0o/SchemaStore.nvim',
    },
    { -- Java lsp
        'mfussenegger/nvim-jdtls',
    },
    { -- vim-markdown
        'preservim/vim-markdown',
        dependencies = { 'godlygeek/tabular' },
        ft = 'markdown',
    },
}, {
    ui = {},
})

function Format() require('conform').format { lsp_format = 'fallback' } end

vim.keymap.set('n', '[d', function()
    vim.diagnostic.jump { count = -1, float = true }
    vim.cmd('normal! zz')
end, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function()
    vim.diagnostic.jump { count = 1, float = true }
    vim.cmd('normal! zz')
end, { desc = 'Go to next diagnostic message' })

vim.keymap.set('n', '<leader>h', require('telescope.builtin').diagnostics, { desc = 'Open diagnostic quickfix list' })

vim.o.background = 'dark'
vim.api.nvim_set_hl(0, 'Folded', { bg = '#242629' })
vim.api.nvim_set_hl(0, 'UfoCursorFoldedLine', { bg = '#484d51' })

-- python
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'python',
    callback = function() vim.keymap.set('i', 'this', 'self') end,
})

-- rust
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'rust',
    callback = function() vim.keymap.set('i', 'pri', 'println!(') end,
})

-- typescript
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'typescript',
    callback = function()
        vim.api.nvim_create_user_command('ImpactClass', function(opts)
            local name = opts.fargs[1]
            local extends = opts.fargs[2]
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, {
                'interface ' .. name .. (extends ~= '' and ' extends ' .. extends or ' ') .. '{',
                '}',
                'interface ' .. name .. 'Constructor extends ImpactClass<' .. name .. '> {',
                'new (): ' .. name,
                '}',
                'var ' .. name .. ': ' .. name .. 'Constructor',
            })
            Format()
        end, {
            nargs = '+',
            complete = function(_, cmdLine, _)
                local argIndex = #vim.split(cmdLine, '%s+')
                if argIndex == 2 then
                    return {}
                elseif argIndex == 3 then
                    return { 'ig.Class' }
                else
                    return {}
                end
            end,
        })

        vim.api.nvim_create_user_command('TypedefsBeg', function(_)
            vim.cmd('normal G$o')
            vim.cmd('normal xxx')
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, {
                '',
                'export {}',
                '',
                'declare global {',
                'namespace sc {}',
                'namespace ig {}',
                '}',
            })
            Format()
        end, {})
        vim.cmd([[
            let @o='f:r=i ;l'
            let @p='^df.Ienum ;lf=xx100@o'
        ]])
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'typescript',
    callback = function()
        vim.keymap.set('n', '<leader>tf', '<cmd>TSToolsRemoveUnusedImports<CR><cmd>TSToolsAddMissingImports<CR>')
    end,
})

-- javascript
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'javascript',
    callback = function() vim.keymap.set('n', '<leader>m', "mn?ig.module<CR><cmd>noh<CR>yi'`n<cmd>echo @+<CR>") end,
})

vim.api.nvim_create_autocmd('BufRead', {
    pattern = '*.json.patch*',
    callback = function() vim.opt.filetype = 'json' end,
})
