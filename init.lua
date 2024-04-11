-- vars
vim.o.clipboard = 'unnamedplus'

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

    set cursorline
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
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-telescope/telescope-fzf-native.nvim' },
        opts = {
            defaults = {
                preview = {
                    mime_hook = function(filepath, bufnr, opts)
                        local is_image = function(filepath1)
                            local image_extensions = { 'png', 'jpg' } -- Supported image formats
                            local split_path = vim.split(filepath1:lower(), '.', { plain = true })
                            local extension = split_path[#split_path]
                            return vim.tbl_contains(image_extensions, extension)
                        end
                        if is_image(filepath) then
                            local term = vim.api.nvim_open_term(bufnr, {})
                            local function send_output(_, data, _)
                                for _, d in ipairs(data) do
                                    vim.api.nvim_chan_send(term, d .. '\r\n')
                                end
                            end
                            vim.fn.jobstart({
                                'catimg',
                                filepath, -- Terminal image viewer command
                            }, {
                                on_stdout = send_output,
                                stdout_buffered = true,
                                pty = true,
                            })
                        else
                            require('telescope.previewers.utils').set_preview_message(
                                bufnr,
                                opts.winid,
                                'Binary cannot be previewed'
                            )
                        end
                    end,
                },
            },
        },
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
        },
    },
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        lazy = true,
    },
    {
        'nvim-treesitter/nvim-treesitter',
        opts = {
            ensure_installed = {},
            sync_install = false,
            markid = { enable = true },
            auto_install = true,

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
        config = function(_, opts) require('nvim-treesitter.configs').setup(opts) end,
    },
    'tpope/vim-surround',
    {
        'Darazaki/indent-o-matic',
        config = function(_, _) require('indent-o-matic').setup({}) end,
    },
    {
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
                    local winid = require('ufo').peekFoldedLinesUnderCursor()
                    if not winid then vim.fn.CocActionAsync('definitionHover') end
                end,
            },
        },
    },
    {
        'sanfusu/neovim-undotree',
        keys = { { '<leader>u', '<cmd>UndotreeToggle<cr>' } },
    },
    {
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
    {
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                javascript = { 'prettierd', 'prettier' },
                typescript = { 'prettierd', 'prettier' },
                json = { 'jsonprettierd' },
                sh = { 'shfmt' },
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
        config = function(_, opts) require('conform').setup(opts) end,
        keys = {
            {
                '\\f',
                function() Format() end,
                mode = { 'n', 'v' },
                desc = 'Format the current buffer',
            },
        },
    },
    {
        'neoclide/coc.nvim',
        build = 'npm ci',
        lazy = false,
        config = function(_, _)
            vim.cmd([[
                inoremap <silent><expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
                inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
                inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"
            ]])
        end,
        keys = {
            { '[d', '<Plug>(coc-diagnostic-prev-error)' },
            { ']d', '<Plug>(coc-diagnostic-next-error)' },
            { '[f', '<Plug>(coc-diagnostic-prev)' },
            { ']f', '<Plug>(coc-diagnostic-next)' },

            { '<leader>gD', '<Plug>(coc-declaration)' },
            { '<leader>gd', '<Plug>(coc-definition)' },

            { 'K', ':call CocActionAsync("doHover")<cr><C-L>' },

            { '<leader>s', '<Plug>(coc-rename)' },
            { '<leader>ca', '<Plug>(coc-codeaction)' },
            { '<leader>gs', '<Plug>(coc-references)' },
        },
        event = { 'InsertEnter' },
    },
    {
        'preservim/vim-markdown',
        dependencies = { 'godlygeek/tabular' },
        ft = 'markdown',
    },
    {
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
    {
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
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {},
        keys = {
            { '<leader>lt', '<cmd>ToggleTerm direction=horizontal size=15<cr>' },
            { '<leader>ly', '<cmd>ToggleTerm direction=vertical size=80<cr>' },
        },
    },
    {
        'ribru17/bamboo.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            colors = {
                black = '#111210',
                bg0 = '#1d1f21', -- '#252623',
                bg1 = '#2f312c',
                bg2 = '#383b35',
                bg3 = '#3a3d37',
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
}, {})

function Format() require('conform').format({ lsp_fallback = true }) end

vim.o.background = 'dark'

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

vim.keymap.set('', '<esc>', '<nop>')
vim.keymap.set('i', '<esc>', '<nop>')
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

vim.keymap.set('n', '<leader>t', ':set wrap!<cr><C-L>')
vim.keymap.set('n', '<leader>l', ':noh<cr><C-L>')
vim.keymap.set('', '<leader>z', ':%y<cr>')

vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzvzz')
vim.keymap.set('n', 'N', 'Nzzzvzz')

vim.keymap.set('t', '<leader>q', '<cmd>:q!<cr>')
vim.keymap.set('t', '<leader>lt', '<cmd>:q!<cr>')
vim.keymap.set('t', '<leader>ly', '<cmd>:q!<cr>')

-- python
vim.cmd(':autocmd FileType python :inoremap <buffer> this self')

-- rust
vim.cmd(':autocmd FileType rust :inoremap <buffer> pri println!(')

-- typescript

function ImpactClass()
    local name = vim.fn.input('Interface name: ')
    local extends = vim.fn.input('Extends: ')
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
end

vim.cmd(':autocmd FileType typescript command! ImpactClass lua ImpactClass()')

function TypedefsBeg()
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
end

vim.cmd(':autocmd FileType typescript command! TypedefBeg lua TypedefsBeg()')

vim.cmd(":autocmd FileType typescript let @o='f:r=i ;l'")
vim.cmd(":autocmd FileType typescript let @p='^df.Ienum ;lf=xx100@o'")

vim.keymap.set(
    'n',
    '<leader>m',
    function()
        require('telescope.builtin').find_files({
            default_text = vim.fn.getreg('+'),
        })
    end
)

-- javascript
vim.cmd(
    ':autocmd FileType javascript lua vim.keymap.set("n", "<leader>m", "mn?ig.module<CR>:noh<CR>yi\\\'`n:echo @+<CR>")'
)

-- markdown
vim.cmd(':autocmd FileType markdown command! Preview :CocCommand markdown-preview-enhanced.openPreview')

vim.cmd(':autocmd FileType markdown command! Preview :CocCommand markdown-preview-enhanced.openPreview')

vim.cmd("autocmd BufRead *.json.patch lua vim.opt.filetype = 'json'")
vim.cmd("autocmd BufRead *.json.patch.cond lua vim.opt.filetype = 'json'")
