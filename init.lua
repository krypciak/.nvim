-- vars
vim.o.clipboard = 'unnamedplus'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split'
vim.opt.cursorline = true

vim.o.relativenumber = true
vim.wo.number = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.api.nvim_set_keymap('n', '<Space>', '', {})
vim.g.mapleader = ' '

vim.o.undofile = true
vim.o.undodir = vim.fn.expand('$HOME/.cache/nvim/undo/')

vim.opt.rtp:append('/usr/share/vim/vimfiles')

vim.cmd([[
augroup remember_folds
  autocmd!
  autocmd BufWinLeave *.* mkview
  autocmd BufWinEnter *.* silent! loadview
augroup END
]])
vim.cmd([[set viewoptions-=curdir]])

vim.o.foldcolumn = '0'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'nvim_treesitter#foldexpr()'

vim.cmd([[
    :highlight Folded ctermbg=237
    :highlight Pmenu ctermbg=233 ctermfg=254

    :highlight PmenuSel ctermbg=238 ctermfg=255

    hi cursorline cterm=none term=none
    autocmd WinEnter * setlocal cursorline
    autocmd WinLeave * setlocal nocursorline
    highlight CursorLine ctermbg=235

    set ff=unix
    set redrawtime=0
]])

-- Return to last edit position when opening files
vim.cmd([[
    autocmd BufReadPost *
         \ if line("'\"") > 0 && line("'\"") <= line("$") |
         \   exe "normal! g`\"" |
         \ endif
]])

-- Save opened folds
vim.cmd([[
    set viewoptions-=curdir
    set viewoptions-=options
    augroup remember_folds
        autocmd!
        autocmd BufWinLeave *.* if &ft !=# 'help' | mkview | endif
        autocmd BufWinEnter *.* if &ft !=# 'help' | silent! loadview | endif
    augroup END
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

-- plugins
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    'itchyny/lightline.vim',
    { -- telescope
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-telescope/telescope-fzf-native.nvim' },
        lazy = false,
        opts = {},
        setup = function(_, opts)
            local telescope = require('telescope')
            telescope.load_extension('fzf')
            telescope.setup(opts)
        end,
        keys = {
            { '<leader>fa', '<cmd>Telescope git_files show_untracked=true<cr>' },
            { '<leader>fA', '<cmd>Telescope find_files no_ignore=true no_ignore_parent=true<cr>' },
            { '<leader>fs', '<cmd>Telescope live_grep<cr>' },
            { '<leader>fd', '<cmd>Telescope current_buffer_fuzzy_find<cr>' },
            { '<leader>fg', '<cmd>Telescope git_bcommits<cr>' },
            {
                '<leader>m',
                function()
                    require('telescope.builtin').find_files({
                        default_text = vim.fn.getreg('+'),
                    })
                end,
            },
            {
                '<leader>fe',
                function()
                    local actions = require('telescope.actions')
                    local action_state = require('telescope.actions.state')
                    local finders = require('telescope.finders')
                    local pickers = require('telescope.pickers')
                    local sorters = require('telescope.sorters')

                    local lines =
                        vim.split(vim.fn.system("cliphist list | awk '{print substr($0, index($0, $2))}'"), '\n')
                    local opts = {
                        prompt_title = 'Cliphist',
                        finder = finders.new_table({
                            results = lines,
                        }),
                        sorter = sorters.get_generic_fuzzy_sorter(),
                        attach_mappings = function(_, map)
                            function os.capture(cmd)
                                local f = assert(io.popen(cmd, 'r'))
                                local s = assert(f:read('*a'))
                                f:close()
                                return s
                            end
                            local function decode_and_paste(prompt_bufnr)
                                local selection = action_state.get_selected_entry(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                if selection then vim.fn.setreg('+', selection.value) end
                            end
                            map('i', '<CR>', decode_and_paste)
                            map('n', '<CR>', decode_and_paste)
                            return true
                        end,
                    }

                    pickers.new(opts, {}):find()
                end,
            },
        },
    },
    { -- telescope-fzf-native
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        lazy = true,
    },
    { -- treesitter
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        opts = {
            ensure_installed = {},
            sync_install = false,
            markid = { enable = true },
            auto_install = true,
            indent = { enable = true },

            highlight = {
                enable = true,
                disable = function(_, buf)
                    local max_filesize = 3 * 1024 * 1024 -- 3 MB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then return true end
                end,
                additional_vim_regex_highlighting = false,
            },
        },
        config = function(_, opts)
            require('nvim-treesitter.install').prefer_git = true
            require('nvim-treesitter.configs').setup(opts)
        end,
    },
    'tpope/vim-surround',
    { -- indent-o-matic
        'Darazaki/indent-o-matic',
        opts = {},
    },
    { -- ufo
        'kevinhwang91/nvim-ufo',
        lazy = false,
        dependencies = { 'kevinhwang91/promise-async' },
        opts = {
            open_fold_hl_timeout = 0,
            close_fold_kinds_for_ft = { 'imports', 'comment' },
            fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
                local newVirtText = {}
                local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                local sufWidth = vim.fn.strdisplaywidth(suffix)
                local targetWidth = width - sufWidth
                local curWidth = 0
                for _, chunk in ipairs(virtText) do
                    local chunkText = chunk[1]
                    local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                    if targetWidth > curWidth + chunkWidth then
                        table.insert(newVirtText, chunk)
                    else
                        chunkText = truncate(chunkText, targetWidth - curWidth)
                        local hlGroup = chunk[2]
                        table.insert(newVirtText, { chunkText, hlGroup })
                        chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        -- str width returned from truncate() may less than 2nd argument, need padding
                        if curWidth + chunkWidth < targetWidth then
                            suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                        end
                        break
                    end
                    curWidth = curWidth + chunkWidth
                end
                table.insert(newVirtText, { suffix, 'MoreMsg' })
                return newVirtText
            end,
            preview = {
                win_config = {
                    border = { '', ' ', '', '', '', ' ', '', '' },
                    winhighlight = 'Normal:Folded',
                    winblend = 0,
                },
                mappings = {
                    jumpTop = '[',
                    jumpBot = ']',
                },
            },
            provider_selector = function(_, _, _) return { 'treesitter', 'indent' } end,
        },
        config = function(_, opts)
            require('ufo').setup(opts)

            vim.api.nvim_create_autocmd('FileType', {
                pattern = { 'markdown' },
                callback = function() require('ufo').detach() end,
            })
        end,
        keys = {
            { 'zr', function() require('ufo').openFoldsExceptKinds() end },
            { 'zm', function() require('ufo').closeFoldsWith() end },
            { 'zR', function() require('ufo').openAllFolds() end },
            { 'zM', function() end },
            {
                'L',
                function()
                    -- todo
                    local winid = require('ufo').peekFoldedLinesUnderCursor()
                    -- if not winid then vim.fn.CocActionAsync('definitionHover')
                    -- end
                end,
            },
        },
    },
    { -- undotree
        'sanfusu/neovim-undotree',
        keys = { { '<leader>u', '<cmd>UndotreeToggle<cr>' } },
    },
    { -- harpoon
        'ThePrimeagen/harpoon',
        branch = 'harpoon2',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function(_, _)
            Harpoon = require('harpoon')
            Harpoon:setup()

            -- basic telescope configuration
            local conf = require('telescope.config').values
            function Toggle_telescope(harpoon_files)
                local file_paths = {}
                for _, item in ipairs(harpoon_files.items) do
                    table.insert(file_paths, item.value)
                end

                require('telescope.pickers')
                    .new({}, {
                        prompt_title = 'Harpoon',
                        finder = require('telescope.finders').new_table({
                            results = file_paths,
                        }),
                        previewer = conf.file_previewer({}),
                        sorter = conf.generic_sorter({}),
                    })
                    :find()
            end
        end,
        keys = {
            -- { '<leader>fl', function() Toggle_telescope(Harpoon:list()) end },
            -- { '<leader>fa', function() Harpoon:list():append() end },
            -- { '<leader>fc', function() Harpoon:list():clear() end },
            -- { '<leader>fq', function() Harpoon:list():select(1) end },
            -- { '<leader>fw', function() Harpoon:list():select(2) end },
            -- { '<leader>fe', function() Harpoon:list():select(3) end },
            -- { '<leader>fr', function() Harpoon:list():select(4) end },
        },
    },
    { 'nvim-tree/nvim-web-devicons', lazy = true },
    { -- conform
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                javascript = { 'prettierd', 'prettier' },
                typescript = { 'prettierd', 'prettier' },
                json = { 'jsonprettierd' },
                sh = { 'shfmt' },
                python = { 'black' },
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
                '\\f',
                function() Format() end,
                mode = { 'n', 'v', 'i' },
                desc = 'Format the current buffer',
            },
        },
    },
    { -- lspconfig
        'neovim/nvim-lspconfig',
        dependencies = {
            -- Automatically install LSPs and related tools to stdpath for Neovim
            { 'williamboman/mason.nvim', config = true },
            'williamboman/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',

            -- Useful status updates for LSP.
            { 'j-hui/fidget.nvim', opts = {} },

            -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins used for completion, annotations and signatures of Neovim apis
            { 'folke/neodev.nvim', opts = {} },
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
                    map('<leader>gD', vim.lsp.buf.declaration, 'goto declaration')

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
                end,
            })

            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

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
                -- clangd = {},
                -- gopls = {},
                -- pyright = {},
                -- rust_analyzer = {},
                -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
                --
                -- Some languages (like typescript) have entire language plugins that can be useful:
                --    https://github.com/pmizio/typescript-tools.nvim
                --
                -- But for many setups, the LSP (`tsserver`) will work just fine
                -- tsserver = {},
                --

                lua_ls = {
                    -- cmd = {...},
                    -- filetypes = { ...},
                    -- capabilities = {},
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = 'Replace',
                            },
                            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                            -- diagnostics = { disable = { 'missing-fields' } },
                        },
                    },
                },
                tsserver = {
                    settings = {
                        typescript = {
                            inlayHints = {
                                includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all'
                                includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                                includeInlayVariableTypeHints = true,
                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
                            },
                        },
                        javascript = {
                            inlayHints = {
                                includeInlayParameterNameHints = 'all', -- 'none' | 'literals' | 'all'
                                includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                                includeInlayVariableTypeHints = true,

                                includeInlayFunctionParameterTypeHints = true,
                                includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                                includeInlayPropertyDeclarationTypeHints = true,
                                includeInlayFunctionLikeReturnTypeHints = true,
                                includeInlayEnumMemberValueHints = true,
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
            }

            -- Ensure the servers and tools above are installed
            --  To check the current status of installed tools and/or manually install
            --  other tools, you can run
            --    :Mason
            --
            --  You can press `g?` for help in this menu.
            require('mason').setup()

            -- You can add other tools here that you want Mason to install
            -- for you, so that they are available from within Neovim.
            local ensure_installed = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed, {
                'stylua', -- Used to format Lua code
            })
            require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

            require('mason-lspconfig').setup({
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        -- This handles overriding only values explicitly passed
                        -- by the server configuration above. Useful when disabling
                        -- certain features of an LSP (for example, turning off formatting for tsserver)
                        server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
                        require('lspconfig')[server_name].setup(server)
                    end,
                },
            })
        end,
    },
    { -- nvim-cmp
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            {
                'L3MON4D3/LuaSnip',
                build = (function()
                    -- Build Step is needed for regex support in snippets.
                    -- This step is not supported in many windows environments.
                    -- Remove the below condition to re-enable on windows.
                    if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then return end
                    return 'make install_jsregexp'
                end)(),
                dependencies = {
                    {
                        'rafamadriz/friendly-snippets',
                        config = function() require('luasnip.loaders.from_vscode').lazy_load() end,
                    },
                },
            },
            'saadparwaiz1/cmp_luasnip',

            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-path',
        },
        config = function()
            local cmp = require('cmp')
            local luasnip = require('luasnip')
            luasnip.config.setup({})

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                completion = { completeopt = 'menu,menuone,noinsert' },

                -- For an understanding of why these mappings were
                -- chosen, you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                mapping = cmp.mapping.preset.insert({
                    -- -- Select the [n]ext item
                    -- ['<C-n>'] = cmp.mapping.select_next_item(),
                    -- -- Select the [p]revious item
                    -- ['<C-p>'] = cmp.mapping.select_prev_item(),

                    -- Scroll the documentation window [b]ack / [f]orward
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),

                    -- -- Accept ([y]es) the completion.
                    -- --  This will auto-import if your LSP supports it.
                    -- --  This will expand snippets if the LSP sent a snippet.
                    -- ['<C-y>'] = cmp.mapping.confirm({ select = true }),

                    -- If you prefer more traditional completion keymaps,
                    -- you can uncomment the following lines
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping.select_next_item(),
                    ['<S-Tab>'] = cmp.mapping.select_prev_item(),

                    -- Manually trigger a completion from nvim-cmp.
                    --  Generally you don't need this, because nvim-cmp will display
                    --  completions whenever it has completion options available.
                    ['<C-Space>'] = cmp.mapping.complete({}),

                    -- Think of <c-l> as moving to the right of your snippet expansion.
                    --  So if you have a snippet that's like:
                    --  function $name($args)
                    --    $body
                    --  end
                    --
                    -- <c-l> will move you to the right of each of the expansion locations.
                    -- <c-h> is similar, except moving you backwards.
                    -- TODO: dont understand
                    -- ['<C-l>'] = cmp.mapping(function()
                    --     if luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump() end
                    -- end, { 'i', 's' }),
                    -- ['<C-h>'] = cmp.mapping(function()
                    --     if luasnip.locally_jumpable(-1) then luasnip.jump(-1) end
                    -- end, { 'i', 's' }),
                    --
                    -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                    --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
                }),
                sources = {
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                    { name = 'path' },
                },
            })
        end,
    },
    { -- vim-markdown
        'preservim/vim-markdown',
        dependencies = { 'godlygeek/tabular' },
        ft = 'markdown',
    },
    { -- context.nvim
        'Hippo0o/context.vim',
        cmd = {
            'ContextActivate',
            'ContextDisable',
            'ContextDisableWIndow',
            'ContextEnable',
            'ContextEnableWindow',
            'ContextPeek',
            'ContextToggle',
            'ContextToggleWindow',
            'ContextUpdate',
        },
        keys = {
            { '<leader>cp', '<cmd>ContextPeek<cr>', desc = 'ContextPeek' },
        },
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
            { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
        },
    },
    { -- toggleterm
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {},
        keys = {
            { '<leader>lt', '<cmd>ToggleTerm direction=horizontal size=15<cr>' },
            { '<leader>ly', '<cmd>ToggleTerm direction=vertical size=80<cr>' },
        },
    },
    { -- bamboo
        'ribru17/bamboo.nvim',
        lazy = false,
        priority = 1000,
        enabled = true,
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
    { -- autopairs
        'windwp/nvim-autopairs',
        dependencies = { 'hrsh7th/nvim-cmp' },
        event = 'InsertEnter',
        lazy = false,
        priority = 1000,
        opts = {},
        config = function(_, opts)
            local autopairs = require('nvim-autopairs')
            autopairs.setup(opts)

            local cmp_autopairs = require('nvim-autopairs.completion.cmp')
            local cmp = require('cmp')
            cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
        end,
    },
    { 'numToStr/Comment.nvim', opts = {} },
    { 'hiphish/rainbow-delimiters.nvim' },
    { -- todo-comments
        'folke/todo-comments.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {},
        event = 'VimEnter',
        keys = {
            { ']t', function() require('todo-comments').jump_next() end, { desc = 'Next todo comment' } },
            { '[t', function() require('todo-comments').jump_prev() end, { desc = 'Previous todo comment' } },
        },
    },
    {
        'iamcco/markdown-preview.nvim',
        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },
        build = function() vim.fn['mkdp#util#install']() end,
    },
    -- LSP's
    { -- typescript-tools
        -- TODO: Revert
        'notomo/typescript-tools.nvim',
        branch = 'fix-deprecated',
        dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
        opts = {},
    },
    {
        'b0o/SchemaStore.nvim',
    },
}, {})

function Format() require('conform').format({ lsp_fallback = true }) end

vim.keymap.set('n', '[d', function()
    vim.diagnostic.goto_prev()
    vim.cmd('normal! zz4<c-e>')
end, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', function()
    vim.diagnostic.goto_next()
    vim.cmd('normal! zz4<c-e>')
end, { desc = 'Go to next diagnostic message' })

vim.keymap.set('n', '<leader>h', vim.diagnostic.setloclist, { desc = 'Open diagnostic quickfix list' })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function() vim.highlight.on_yank() end,
})

vim.o.background = 'dark'
vim.api.nvim_set_hl(0, 'Folded', { bg = '#242629' })
vim.api.nvim_set_hl(0, 'UfoCursorFoldedLine', { bg = '#484d51' })

-- Run/Compile keybinding
vim.keymap.set('n', '<leader>j', function()
    -- ftype = vim.bo.filetyp
    -- if ftype == 'rust' then rust_run()
    -- elseif ftype == 'python' then python_run()
    -- elseif ftype == 'sh' then sh_run()
    -- else print('Unsupported filetype: '.. ftype) end
end)

-- Build keybinding
vim.keymap.set('n', '<leader>k', function()
    -- ftype = vim.bo.filetype
    -- if ftype == 'rust' then rust_build()
    -- elseif ftype == 'c' then c_build()
    -- elseif ftype == 'cpp' then c_build()
    -- else print('Unsupported filetype: '.. ftype) end
end)

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

vim.keymap.set('', '<leader>q', ':q<cr>')
vim.keymap.set('', '<leader>w', ':w<cr>')
vim.keymap.set('', '<leader>r', ':q!<cr>')
vim.keymap.set('', '<leader>e', ':wq<cr>')

vim.keymap.set('v', ';;', '<esc>')
vim.keymap.set('i', ';l', '<esc>')
vim.keymap.set('t', ';l', '<C-\\><C-n>')

vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

vim.keymap.set('t', '<C-h>', '<cmd>wincmd h<CR>')
vim.keymap.set('t', '<C-j>', '<cmd>wincmd j<CR>')
vim.keymap.set('t', '<C-k>', '<cmd>wincmd k<CR>')
vim.keymap.set('t', '<C-l>', '<C-l><cmd>wincmd l<CR>')

vim.keymap.set('n', '<leader>tw', ':set wrap!<cr><C-L>')
vim.keymap.set('n', '<leader>l', ':nohlsearch<cr><C-L>')
vim.keymap.set('', '<leader>z', ':%y<cr>')

vim.keymap.set('n', 'zz', 'zz4<c-e>')
vim.keymap.set('n', 'Z', 'zz4<c-e>')
vim.keymap.set('n', '<C-d>', '<C-d>zz4<c-e>')
vim.keymap.set('n', '<C-u>', '<C-u>zz4<c-e>')
vim.keymap.set('n', 'n', 'nzzzvzz4<c-e>')
vim.keymap.set('n', 'N', 'Nzzzvzz4<c-e>')
vim.keymap.set('n', '<c-o>', '<c-o>zz4<c-e>')
vim.keymap.set('n', '<c-i>', '<c-i>zz4<c-e>')

vim.keymap.set('t', '<c-q>', '<cmd>:q!<cr>')

-- spelling stuff
vim.opt.spelllang = 'en_us'
vim.opt.spell = false
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown',
    callback = function() vim.opt_local.spell = true end,
})
vim.keymap.set('', '<leader>p', ':setlocal spell!<cr>')

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

-- javascript
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'javascript',
    callback = function() vim.keymap.set('n', '<leader>m', "mn?ig.module<CR>:noh<CR>yi'`n:echo @+<CR>") end,
})

vim.api.nvim_create_autocmd('BufRead', {
    pattern = '*.json.patch*',
    callback = function() vim.opt.filetype = 'json' end,
})
