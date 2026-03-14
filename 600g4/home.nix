{ config, pkgs, inputs, lib, ... }:

{

  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";
  home.stateVersion = "25.11";

  home.sessionPath = [ "$HOME/.local/bin" ];

  # ── AGS (Aylur's GTK Shell) ──────────────────────────────────────────────────
  # The installed AGS wrapper bundles both GTK3+GTK4 causing conflicts.
  # nix shell gives a clean environment; nix caches it after first run.
  home.file.".local/bin/ags" = {
    text = ''
      #!/bin/sh
      exec nix shell github:aylur/ags --command ags "$@"
    '';
    executable = true;
  };

  # ── Session Variables ────────────────────────────────────────────────────────
  dconf.settings = {
      "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme     = "Tokyonight-Dark";
          icon-theme    = "Papirus-Dark";
          cursor-theme  = "Adwaita";
          cursor-size   = 24;
      };
      "org/nemo/desktop" = {
          use-desktop-grid = false;
      };
      "org/nemo/preferences" = {
          default-folder-viewer = "list-view";
          show-hidden-files     = false;
      };
  };

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND  = "1";
    XDG_SESSION_TYPE    = "wayland";
    GSETTINGS_BACKEND   = "keyfile";
  };

  # ── Shell: fish ──────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx TERMINAL alacritty
      zoxide init fish | source
    '';
    shellAliases = {
      v         = "nvim";
      ls        = "ls --color=auto";
      ll        = "ls -lah --color=auto";
      ".."      = "cd ..";
      "..."     = "cd ../..";
      rebuild   = "sudo nixos-rebuild switch --flake /home/otakuracer/nixos-config/600g4#600g4-nixos";
      conf      = "nvim /home/otakuracer/nixos-config/600g4/configuration.nix";
      hm        = "nvim /home/otakuracer/nixos-config/600g4/home.nix";
      flk       = "nvim /home/otakuracer/nixos-config/600g4/flake.nix";
      nix-gc    = "sudo nix-collect-garbage -d";
      nix-list  = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system/";
      hyprcon    = "nvim /home/otakuracer/.config/hypr/hyprland.conf";
    };
  };

  # ── Neovim + lazy.nvim ───────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      nixd
      lua-language-server
      nodePackages.bash-language-server
      qt6.qtdeclarative   # qmlls
      ripgrep
      fd
    ];

    initLua = ''
      -- ── Options ──────────────────────────────────────────────────────────────
      -- Leader key must be set before lazy loads
      vim.g.mapleader      = " "
      vim.g.maplocalleader = "\\"

      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.expandtab      = true
      vim.opt.shiftwidth     = 4
      vim.opt.softtabstop    = 4
      vim.opt.tabstop        = 4
      vim.opt.smartindent    = true
      vim.opt.showmatch      = true
      vim.opt.mouse          = "a"
      vim.opt.clipboard      = "unnamedplus"
      vim.opt.termguicolors  = true
      vim.opt.signcolumn     = "yes"
      vim.opt.updatetime     = 250
      vim.opt.scrolloff      = 8
      vim.opt.wrap           = false

      -- ── Bootstrap lazy.nvim ──────────────────────────────────────────────────
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git", "clone", "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable", lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      -- ── Plugins ──────────────────────────────────────────────────────────────
      require("lazy").setup({

        -- Colorscheme
        {
          "folke/tokyonight.nvim",
          lazy = false,
          priority = 1000,
          config = function()
            require("tokyonight").setup({ style = "night" })
            vim.cmd("colorscheme tokyonight")
          end,
        },

        -- File tree
        {
          "nvim-tree/nvim-tree.lua",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          config = function()
            require("nvim-tree").setup()
            vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { silent = true })
          end,
        },

        -- Fuzzy finder
        {
          "ibhagwan/fzf-lua",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          config = function()
            local fzf = require("fzf-lua")
            fzf.setup({
              "telescope",
              winopts = {
                height  = 0.80,
                width   = 0.85,
                preview = { layout = "horizontal", ratio = 60 },
              },
              keymap = {
                fzf = { ["ctrl-q"] = "select-all+accept" },  -- send all to quickfix
              },
            })
            vim.keymap.set("n", "<leader>ff", fzf.files,        { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", fzf.live_grep,    { desc = "Live grep" })
            vim.keymap.set("n", "<leader>fb", fzf.buffers,      { desc = "Buffers" })
            vim.keymap.set("n", "<leader>fr", fzf.oldfiles,     { desc = "Recent files" })
            vim.keymap.set("n", "<leader>fh", fzf.help_tags,    { desc = "Help tags" })
            vim.keymap.set("n", "<leader>/",  fzf.grep_curbuf,  { desc = "Grep current buffer" })
            vim.keymap.set("n", "<leader>gs", fzf.git_status,   { desc = "Git status (fzf)" })
          end,
        },

        -- Treesitter
        {
          "nvim-treesitter/nvim-treesitter",
          build = ":TSUpdate",
          config = function()
            require("nvim-treesitter.config").setup({
              ensure_installed = { "nix", "lua", "bash", "qmljs", "python", "javascript" },
              highlight = { enable = true },
              indent    = { enable = true },
            })
          end,
        },

        -- LSP
        {
          "neovim/nvim-lspconfig",
          config = function()
            local caps = require("cmp_nvim_lsp").default_capabilities()

            vim.lsp.config("nixd", { capabilities = caps })
            vim.lsp.config("lua_ls", {
                capabilities = caps,
                settings = { Lua = { diagnostics = { globals = { "vim" } } } },
            })
            vim.lsp.config("bashls", { capabilities = caps })
            vim.lsp.config("qmlls", { capabilities = caps })

            vim.lsp.enable({ "nixd", "lua_ls", "bashls", "qmlls" })

            -- Keymaps on attach
            vim.api.nvim_create_autocmd("LspAttach", {
              callback = function(ev)
                local opts = { buffer = ev.buf }
                vim.keymap.set("n", "gd",         vim.lsp.buf.definition,      opts)
                vim.keymap.set("n", "K",           vim.lsp.buf.hover,           opts)
                vim.keymap.set("n", "<leader>rn",  vim.lsp.buf.rename,          opts)
                vim.keymap.set("n", "<leader>ca",  vim.lsp.buf.code_action,     opts)
                vim.keymap.set("n", "[d",          vim.diagnostic.goto_prev,    opts)
                vim.keymap.set("n", "]d",          vim.diagnostic.goto_next,    opts)
              end,
            })
          end,
        },

        -- Autocompletion
        {
          "hrsh7th/nvim-cmp",
          dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
          },
          config = function()
            local cmp     = require("cmp")
            local luasnip = require("luasnip")
            cmp.setup({
              snippet = {
                expand = function(args) luasnip.lsp_expand(args.body) end,
              },
              mapping = cmp.mapping.preset.insert({
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                ["<Tab>"]     = cmp.mapping(function(fallback)
                  if cmp.visible() then cmp.select_next_item()
                  else fallback() end
                end, { "i", "s" }),
              }),
              sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
              }),
            })
          end,
        },

        -- Status line
        {
          "nvim-lualine/lualine.nvim",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          config = function()
            require("lualine").setup({ options = { theme = "tokyonight" } })
          end,
        },

        -- Auto pairs
        {
          "windwp/nvim-autopairs",
          event = "InsertEnter",
          config = true,
        },

        -- Git signs
        {
          "lewis6991/gitsigns.nvim",
          config = true,
        },

        -- Comment
        {
          "numToStr/Comment.nvim",
          config = true,
        },

        -- Indent guides
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            config = function()
                require("ibl").setup({
                    indent = {
                        char = "┃",
                        highlight = "IblIndent",
                    },
                    scope = {
                        enabled = true,
                        char = "┃",
                        highlight = "IblScope",
                    },
                })
                vim.api.nvim_create_autocmd("ColorScheme", {
                    pattern = "*",
                    callback = function()
                        vim.api.nvim_set_hl(0, "IblIndent", { fg = "#e0ff00" })
                        vim.api.nvim_set_hl(0, "IblScope",  { fg = "#9d7cd8" })
                    end,
                })
                vim.api.nvim_set_hl(0, "IblIndent", { fg = "#e0ff00" })
                vim.api.nvim_set_hl(0, "IblScope",  { fg = "#9d7cd8" })
            end,
        },

        -- Git TUI (complements gitsigns)
        {
          "tpope/vim-fugitive",
          cmd = { "Git", "Gdiffsplit", "Gblame", "Gclog" },
          keys = {
            { "<leader>gg", "<cmd>Git<CR>",        desc = "Git status (fugitive)" },
            { "<leader>gc", "<cmd>Git commit<CR>", desc = "Git commit" },
            { "<leader>gP", "<cmd>Git push<CR>",   desc = "Git push" },
            { "<leader>gl", "<cmd>Git pull<CR>",   desc = "Git pull" },
            { "<leader>gD", "<cmd>Gdiffsplit<CR>", desc = "Git diff split" },
          },
        },

        -- Buffer tabs
        {
          "akinsho/bufferline.nvim",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          event = "VeryLazy",
          config = function()
            require("bufferline").setup({
              options = {
                mode             = "buffers",
                numbers          = "ordinal",
                close_command    = "bdelete! %d",
                diagnostics      = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                  local icons = { error = " ", warning = " " }
                  return (icons[level] or "") .. count
                end,
                offsets = {{
                  filetype  = "NvimTree",
                  text      = "File Explorer",
                  highlight = "Directory",
                  separator = true,
                }},
                separator_style         = "slant",
                always_show_bufferline  = true,
              },
            })
            vim.keymap.set("n", "<Tab>",   "<cmd>BufferLineCycleNext<CR>", { silent = true, desc = "Next buffer" })
            vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", { silent = true, desc = "Prev buffer" })
            vim.keymap.set("n", "<leader>bx", "<cmd>BufferLinePickClose<CR>", { silent = true, desc = "Pick close buffer" })
            vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>",             { silent = true, desc = "Delete buffer" })
            for i = 1, 9 do
              vim.keymap.set("n", "<leader>" .. i, function()
                require("bufferline").go_to(i, true)
              end, { silent = true, desc = "Buffer " .. i })
            end
          end,
        },

        -- Keybinding hints
        {
          "folke/which-key.nvim",
          event = "VeryLazy",
          config = function()
            local wk = require("which-key")
            wk.setup({
              delay  = 400,
              win    = { border = "rounded" },
              icons  = { mappings = false },
            })
            wk.add({
              { "<leader>f", group = "Find (fzf-lua)" },
              { "<leader>g", group = "Git" },
              { "<leader>b", group = "Buffer" },
              { "<leader>l", group = "LSP" },
              { "<leader>e", desc  = "Explorer toggle" },
            })
          end,
        },

        -- Inline color previews (#hex, rgb(), etc.)
        {
          "NvChad/nvim-colorizer.lua",
          event = "BufReadPre",
          config = function()
            require("colorizer").setup({
              filetypes = { "*" },
              user_default_options = {
                RGB    = true,
                RRGGBB = true,
                names  = false,
                css    = true,
                css_fn = true,
                mode   = "background",
              },
            })
          end,
        },

      }) -- end lazy.setup

    '';
  };

  # ── Alacritty ────────────────────────────────────────────────────────────────
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        padding = { x = 12; y = 12; };
        decorations = "None";
        opacity = 0.95;
      };
      font = {
        normal = { family = "JetBrains Mono"; style = "Regular"; };
        bold   = { family = "JetBrains Mono"; style = "Bold"; };
        italic = { family = "JetBrains Mono"; style = "Italic"; };
        size   = 12.0;
      };
      colors = {
        primary = {
          background = "#1a1b26";
          foreground = "#c0caf5";
        };
      };
      
      terminal = {
        shell.program = "${pkgs.fish}/bin/fish";
      };

      selection = {
          save_to_clipboard = true;
      };
    };
  };

  # ── Git ──────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
        user.name           = "otakuracer";
        user.email          = "aditmadjid@gmail.com";
        init.defaultBranch  = "main";
        core.editor         = "nvim";
    };
  };

  # ── zoxide ───────────────────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # ── fzf ──────────────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  # ── Starship prompt ──────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
        add_newline = false;

        format = lib.concatStrings [
            "[](fg:#3d59a1)"
            "$username"
            "[](bg:#7aa2f7 fg:#3d59a1)"
            "$directory"
            "[](bg:#2ac3de fg:#7aa2f7)"
            "$git_branch"
            "$git_status"
            "[](bg:#414868 fg:#2ac3de)"
            "$nix_shell"
            "$python"
            "$lua"
            "$nodejs"
            "[](bg:#1a1b26 fg:#414868)"
            "$time"
            "[ ](fg:#1a1b26)"
            ];

        username = {
            show_always = true;
            style_user = "bg:#3d59a1 fg:#c0caf5 bold";
            style_root = "bg:#3d59a1 fg:#ff0000 bold";
            format = "[ $user ]($style)";
        };

        directory = {
            style = "bg:#7aa2f7 fg:#1a1b26 bold";
            format = "[ $path ]($style)";
            truncation_length = 3;
            truncate_to_repo = false;
        };

        git_branch = {
            style = "bg:#2ac3de fg:#1a1b26 bold";
            format = "[ $symbol$branch ]($style)";
            symbol = " ";
        };

        git_status = {
            style = "bg:#2ac3de fg:#1a1b26 bold";
            format = "[$all_status$ahead_behind]($style)";
        };

        time = {
            disabled = false;
            style = "bg:#1a1b26 fg:#7aa2f7 bold";
            format = "[ $time ]($style)";
            time_format = "%H:%M";
        };

        character = {
            success_symbol = "";
            error_symbol = "";
        };

        nix_shell = {
            disabled = false;
            style = "bg:#414868 fg:#7dcfff bold";
            format = "[ ❄️ $name ]($style)";
            impure_msg = "[ ❄️ impure ]($style)";
            pure_msg = "[ ❄️ pure ]($style)";
        };

        python = {
            disabled = false;
            style = "bg:#414868 fg:#e0af68 bold";
            format = "[ 🐍 $version ]($style)";
            detect_files = [ "requirements.txt" ".python-version" "pyproject.toml" ];
        };

        lua = {
            disabled = false;
            style = "bg:#414868 fg:#9d7cd8 bold";
            format = "[ 🌙 $version ]($style)";
            detect_files = [ "*.lua" ".luarc.json" ];
        };

        nodejs = {
            disabled = false;
            style = "bg:#414868 fg:#9ece6a bold";
            format = "[ ⬢ $version ]($style)";
            detect_files = [ "package.json" ".nvmrc" ];
        };
    };
  };

  # ── Polkit agent autostart ───────────────────────────────────────────────────
  systemd.user.services.lxqt-policykit = {
    Unit = {
      Description = "LXQt Polkit authentication agent";
      After       = [ "graphical-session.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent";
      Restart   = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ── Zathura (PDF viewer) ─────────────────────────────────────────────────────
  programs.zathura = {
    enable = true;
    options = {
      default-bg          = "#1a1b26";   # Tokyo Night background
      default-fg          = "#c0caf5";   # Tokyo Night foreground
      statusbar-bg        = "#16161e";   # Tokyo Night background dark
      statusbar-fg        = "#c0caf5";
      inputbar-bg         = "#1a1b26";
      inputbar-fg         = "#c0caf5";
      highlight-color     = "#bb9af7";   # Tokyo Night purple
      highlight-active-color = "#7aa2f7"; # Tokyo Night blue
      font                = "JetBrains Mono 11";
      selection-clipboard = "clipboard";
    };
  };

  # ── mpv (video player) ───────────────────────────────────────────────────────
  programs.mpv = {
    enable = true;
    config = {
      # Hardware acceleration via Intel UHD 630 VAAPI
      hwdec            = "vaapi";
      hwdec-codecs     = "all";
      vo               = "gpu";
      gpu-api          = "vulkan";

      # UI
      osc              = true;
      osd-font         = "JetBrains Mono";
      osd-font-size    = 28;
      osd-color        = "#c0caf5";       # Tokyo Night text
      osd-border-color = "#1a1b26";       # Tokyo Night base

      # Behaviour
      save-position-on-quit = true;
      autofit              = "80%";
    };
    bindings = {
      "WHEEL_UP"   = "add volume 5";
      "WHEEL_DOWN" = "add volume -5";
      "Alt+Enter"  = "cycle fullscreen";
    };
  };

  # ── MIME: video → mpv / celluloid, images → imv, PDF → zathura ──────────────
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    exec = "alacritty -e nvim %F";
    mimeType = [ "text/plain" "text/x-shellscript" ];
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Images → imv
      "image/png"       = "imv.desktop";
      "image/jpeg"      = "imv.desktop";
      "image/gif"       = "imv.desktop";
      "image/webp"      = "imv.desktop";
      "image/tiff"      = "imv.desktop";
      "image/bmp"       = "imv.desktop";
      # PDF → zathura
      "application/pdf" = "org.pwmt.zathura.desktop";
      # Video → mpv
      "video/mp4"       = "mpv.desktop";
      "video/mkv"       = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm"      = "mpv.desktop";
      "video/avi"       = "mpv.desktop";
      "video/mov"       = "mpv.desktop";
      "video/x-flv"     = "mpv.desktop";
      # Audio → mpv
      "audio/mpeg"      = "mpv.desktop";
      "audio/flac"      = "mpv.desktop";
      "audio/ogg"       = "mpv.desktop";
      "audio/wav"       = "mpv.desktop";
      "audio/aac"       = "mpv.desktop";
      # Browser → floorp
      "text/html"                        = "floorp.desktop";
      "x-scheme-handler/http"            = "floorp.desktop";
      "x-scheme-handler/https"           = "floorp.desktop";
      "x-scheme-handler/ftp"             = "floorp.desktop";
      "application/xhtml+xml"            = "floorp.desktop";
      # Directory → nemo
      "inode/directory" = "nemo.desktop";
      #Text
      "text/plain"      = "nvim.desktop";
      "text/x-shellscript" = "nvim.desktop";
    };
  };


  gtk = {
    enable = true;
    theme = {
      name    = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size    = 24;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    name    = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size    = 24;
    gtk.enable  = true;
    x11.enable  = true;
  };

  # qt6ct config for Qt apps (Engrampa, etc.)
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    style=gtk2
    color_scheme_path=
    custom_palette=false
    icon_theme=Papirus-Dark
  '';


  # ── Clipboard: cliphist daemon ───────────────────────────────────────────────
  # Stores clipboard history system-wide, feeds Noctalia clipper
  systemd.user.services.cliphist = {
    Unit = {
      Description = "Clipboard history daemon";
      After       = [ "graphical-session.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart   = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # ── Nemo dark mode via dconf ─────────────────────────────────────────────────

  # ── XDG User Directories ─────────────────────────────────────────────────────
  xdg.userDirs = {
    enable            = true;
    createDirectories = true;
    desktop           = "${config.home.homeDirectory}/Desktop";
    documents         = "${config.home.homeDirectory}/Documents";
    download          = "${config.home.homeDirectory}/Downloads";
    music             = "${config.home.homeDirectory}/Music";
    pictures          = "${config.home.homeDirectory}/Pictures";
    publicShare       = "${config.home.homeDirectory}/Public";
    templates         = "${config.home.homeDirectory}/Templates";
    videos            = "${config.home.homeDirectory}/Videos";
  };

  # ── Waybar ───────────────────────────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer    = "top";
        position = "top";
        height   = 40;
        margin-top   = 8;
        margin-left  = 12;
        margin-right = 12;
        spacing      = 6;

        modules-left   = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right  = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

        "hyprland/workspaces" = {
          format      = "{icon}";
          on-click    = "activate";
          format-icons = {
            "1"     = "󰲠";
            "2"     = "󰲢";
            "3"     = "󰲤";
            "4"     = "󰲦";
            "5"     = "󰲨";
            active  = "󰮯";
            default = "󰊠";
          };
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          format          = "  {}";
          max-length      = 40;
          separate-outputs = true;
        };

        clock = {
          format         = "󰥔  {:%H:%M}";
          format-alt     = "󰃶  {:%A, %d %B %Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format   = "󰻠  {usage}%";
          interval = 2;
        };

        memory = {
          format   = "󰍛  {used:0.1f}G";
          interval = 2;
        };

        pulseaudio = {
          format       = "{icon}  {volume}%";
          format-muted = "󰝟  muted";
          format-icons = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi        = "󰤨  {essid}";
          format-ethernet    = "󰈀  {ifname}";
          format-disconnected = "󰤭  disconnected";
          tooltip-format     = "{ipaddr} via {gwaddr}";
        };

        tray = {
          spacing   = 8;
          icon-size = 16;
        };
      };
    };

    style = ''
      * {
        font-family: "JetBrains Mono", monospace;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }

      /* Tokyo Night palette */
      @define-color bg      #1a1b26;
      @define-color bg-alt  #16161e;
      @define-color bg-hl   #292e42;
      @define-color fg      #c0caf5;
      @define-color fg-dim  #565f89;
      @define-color blue    #7aa2f7;
      @define-color cyan    #7dcfff;
      @define-color green   #9ece6a;
      @define-color yellow  #e0af68;
      @define-color orange  #ff9e64;
      @define-color red     #f7768e;
      @define-color magenta #bb9af7;

      window#waybar {
        background: transparent;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        background: @bg;
        border-radius: 12px;
        padding: 2px 8px;
        border: 1px solid @bg-hl;
      }

      /* Workspaces */
      #workspaces {
        padding: 0 4px;
      }

      #workspaces button {
        padding: 2px 6px;
        color: @fg-dim;
        background: transparent;
        border-radius: 8px;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        color: @fg;
        background: @bg-hl;
      }

      #workspaces button.active {
        color: @blue;
        background: @bg-hl;
      }

      #workspaces button.urgent {
        color: @red;
      }

      /* Window title */
      #window {
        color: @fg-dim;
        padding: 0 8px;
      }

      /* Clock */
      #clock {
        color: @magenta;
        font-weight: bold;
        padding: 0 8px;
      }

      /* CPU */
      #cpu {
        color: @cyan;
        padding: 0 8px;
      }

      /* Memory */
      #memory {
        color: @blue;
        padding: 0 8px;
      }

      /* Audio */
      #pulseaudio {
        color: @green;
        padding: 0 8px;
      }

      #pulseaudio.muted {
        color: @fg-dim;
      }

      /* Network */
      #network {
        color: @yellow;
        padding: 0 8px;
      }

      #network.disconnected {
        color: @red;
      }

      /* Tray */
      #tray {
        padding: 0 6px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        color: @orange;
      }

      tooltip {
        background: @bg-alt;
        border: 1px solid @bg-hl;
        border-radius: 8px;
        color: @fg;
      }
    '';
  };

  programs.home-manager.enable = true;
}
