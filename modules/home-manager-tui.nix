{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  users.users.user.isNormalUser = true;
  users.users.user.shell = pkgs.fish;

  home-manager.users.user =
    { pkgs, ... }:
    {
      nixpkgs.config.allowUnfreePackages = [ "terraform" ];

      home.packages = with pkgs; [
        # Neovim language servers
        haskell-language-server
        nixd
        lua-language-server
        rust-analyzer
        rustc
        cargo
        metals
        coursier
        terraform-ls
        texlab
        basedpyright

        # Formatters for conform.nvim
        ormolu
        rustfmt
        terraform
        tex-fmt
        ruff

        # LaTeX toolchain
        texliveMedium
        zathura

        # Fuzzy finder backend
        ripgrep
      ];

      home.sessionVariables = {
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };

      programs.fish.enable = true;

      # NeoVim
      programs.neovim = {
        enable = true;
        withRuby = false;
        withPython3 = true;

        plugins = with pkgs.vimPlugins; [
          (nvim-treesitter.withPlugins (p: [
            p.haskell
            p.nix
            p.lua
            p.rust
            p.scala
            p.terraform
            p.hcl
            p.latex
            p.bibtex
            p.python
            p.toml
          ]))
          mini-nvim
          nvim-tree-lua
          nvim-web-devicons
          rustaceanvim
          nvim-metals
          plenary-nvim
          vimtex
        ];

        initLua = ''
          vim.g.mapleader = ' '
          vim.g.maplocalleader = ' '

          -- absolute line number on the current line
          vim.opt.number = true

          -- relative numbers on all other lines, for j/k jumps
          vim.opt.relativenumber = true

          -- case sensitive search if the first letter is uppercase
          vim.opt.smartcase = true

          -- make whitespace visible, rendered as defined below
          vim.opt.list = true
          vim.opt.listchars = {
            tab = ">-",
            trail = "·",
            space = "·",
            nbsp = "␣",
            extends = ">",
            precedes = "<",
          }

          -- avoid tabs, use spaces
          vim.opt.expandtab = true

          -- Plugins via native vim.pack
          vim.pack.add({
            'https://github.com/neovim/nvim-lspconfig',
            'https://github.com/stevearc/conform.nvim',
          })

          -- LaTeX (VimTeX)
          vim.g.vimtex_view_method = 'zathura'
          vim.g.vimtex_syntax_enabled = 0

          vim.lsp.enable({ 'hls', 'nixd', 'lua_ls', 'terraformls', 'texlab', 'basedpyright', 'ruff' })

          vim.lsp.config('hls', {
            settings = { haskell = { formattingProvider = 'ormolu' } },
          })

          vim.lsp.config('terraformls', {
            init_options = {
              experimentalFeatures = { prefillRequiredFields = true },
            },
          })

          vim.g.rustaceanvim = {
            server = {
              default_settings = {
                ['rust-analyzer'] = {
                  check = { command = 'clippy' },
                },
              },
            },
          }

          -- Scala
          local metals_config = require('metals').bare_config()
          metals_config.metalsBinaryPath = 'metals'
          vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'scala', 'sbt' },
            callback = function()
              require('metals').initialize_or_attach(metals_config)
            end,
          })

          -- Python
          vim.lsp.config('basedpyright', {
            settings = {
              basedpyright = {
                analysis = {
                  typeCheckingMode = 'standard',
                  autoImportCompletions = true,
                  diagnosticSeverityOverrides = {
                    reportUnusedImport = 'none',
                    reportUnusedVariable = 'none',
                  },
                  inlayHints = {
                    variableTypes = true,
                    callArgumentNames = true,
                    functionReturnTypes = true,
                    genericTypes = false,
                  },
                },
              },
            },
          })

          vim.lsp.config('ruff', {
            on_attach = function(client)
              client.server_capabilities.hoverProvider = false
            end,
          })

          -- IntelliJ-style autocompletion
          -- open the completion menu automatically while typing
          vim.o.autocomplete = true
          -- completion sources: o = LSP via omnifunc, . = words from the current buffer
          vim.o.complete = 'o,.'
          -- show the menu even for a single match, never preselect an item,
          -- and show documentation for the highlighted item in a popup
          vim.o.completeopt = 'menu,menuone,noselect,popup'

          -- disable built-in SQL omni completion, it errors without a dbext DB connection;
          -- keeps SQL syntax highlighting, buffer-word completion still works
          vim.api.nvim_create_autocmd('FileType', {
            pattern = 'sql',
            callback = function()
              vim.bo.omnifunc = ""
            end,
          })

          -- LSP completion glue: snippet expansion and auto-imports on accept
          vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(ev)
              local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))
              if client:supports_method('textDocument/completion') then
                vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = false })
              end
              if client:supports_method('textDocument/inlayHint') then
                vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
              end
            end,
          })

          -- format on save: CLI formatters per filetype, LSP formatting as fallback;
          -- filetypes with neither are saved untouched
          require('conform').setup({
            formatters_by_ft = {
              haskell = { 'ormolu' },
              rust = { 'rustfmt' },
              terraform = { 'terraform_fmt' },
              ['terraform-vars'] = { 'terraform_fmt' },
              hcl = { 'terraform_fmt' },
              tex = { 'tex-fmt' },
              python = { 'ruff_organize_imports', 'ruff_format' },
            },
            format_on_save = {
              timeout_ms = 1000,
              lsp_format = 'fallback',
            },
          })

          vim.diagnostic.config({ virtual_text = true })

          -- Treesitter highlighting
          vim.treesitter.language.register('terraform', 'terraform-vars')
          vim.treesitter.language.register('latex', 'tex')
          vim.treesitter.language.register('bibtex', 'bib')
          vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'haskell', 'nix', 'lua', 'rust', 'scala', 'terraform', 'terraform-vars', 'hcl', 'tex', 'bib', 'python', 'toml' },
            callback = function() pcall(vim.treesitter.start) end,
          })

          -- HCL indentation
          vim.api.nvim_create_autocmd('FileType', {
            pattern = { 'terraform', 'terraform-vars', 'hcl' },
            callback = function()
              vim.bo.shiftwidth = 2
              vim.bo.tabstop = 2
            end,
          })

          -- Folding
          vim.o.foldmethod = 'expr'
          vim.o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.o.foldlevelstart = 99

          -- Navigation
          require('mini.pick').setup()
          require('mini.extra').setup()
          local map = vim.keymap.set
          map('n', '<leader>ff', function() MiniPick.builtin.files() end, { desc = 'Find files' })
          map('n', '<leader>fg', function() MiniPick.builtin.grep_live() end, { desc = 'Live grep' })
          map('n', '<leader>fb', function() MiniPick.builtin.buffers() end, { desc = 'Buffers' })
          map('n', '<leader>fr', function() MiniPick.builtin.resume() end, { desc = 'Resume picker' })
          map('n', '<leader>fs', function() MiniExtra.pickers.lsp({ scope = 'document_symbol' }) end, { desc = 'Document symbols' })
          map('n', '<leader>fS', function() MiniExtra.pickers.lsp({ scope = 'workspace_symbol' }) end, { desc = 'Workspace symbols' })
          map('n', '<leader>fd', function() MiniExtra.pickers.diagnostic() end, { desc = 'Diagnostics' })
          map('n', 'gd', function() MiniExtra.pickers.lsp({ scope = 'definition' }) end, { desc = 'Goto definition' })
          map('n', 'gr', function() MiniExtra.pickers.lsp({ scope = 'references' }) end, { desc = 'References' })

          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1
          require('nvim-tree').setup()
          map('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'File tree' })

          -- Git
          require('mini.diff').setup()
          map('n', '<leader>go', function() MiniDiff.toggle_overlay() end, { desc = 'Diff overlay' })
          map('n', '<leader>gx', 'gHgh', { remap = true, desc = 'Reset hunk' })
          map('n', '<leader>gX', function() MiniDiff.do_hunks(0, 'reset') end, { desc = 'Reset buffer' })
        '';

      };

      programs.git = {
        enable = true;

        aliases = {
          lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
        };
      };

      programs.gpg = {
        enable = true;

        settings = {
          no-greeting = true;
          auto-key-locate = "wkd,keyserver";
          keyserver = "hkps://keys.openpgp.org";
          encrypt-to = "0x56B2CCA5F83AECB4";
        };
      };

      programs.tmux = {
        enable = true;
        plugins = with pkgs; [
          tmuxPlugins.yank
        ];
        extraConfig = ''
          # Your tmux config here
          set -g mouse off
          set -g history-limit 10000
          set -g default-terminal "tmux-256color"
          set -g mode-keys vi
        '';
      };

      home.stateVersion = "25.05";
    };
}
