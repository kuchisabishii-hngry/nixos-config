{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.username = "otakuracer";
  home.homeDirectory = "/home/otakuracer";
  home.stateVersion = "25.11";

  # ── Noctalia Shell ───────────────────────────────────────────────────────────
  programs.noctalia-shell.enable = true;

  # ── Noctalia-qs wrapper ──────────────────────────────────────────────────────
  home.file.".local/bin/noctalia-qs" = {
    text = ''
      #!/bin/sh
      exec /nix/store/$(ls /nix/store | grep quickshell | grep -v '\.drv' | grep -v debug | head -1)/bin/qs "$@"
    '';
    executable = true;
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  # ── Session Variables ────────────────────────────────────────────────────────
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND  = "1";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE    = "wayland";
    XCURSOR_THEME       = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE        = "24";
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
      v    = "nvim";
      ls   = "ls --color=auto";
      ll   = "ls -lah --color=auto";
      ".." = "cd ..";
      "..." = "cd ../..";
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos-config/600g4#600g4-nixos";
    };
    functions = {
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXX")
        yazi $argv --cwd-file=$tmp
        if set cwd (cat -- $tmp); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          cd -- $cwd
        end
        rm -f -- $tmp
      '';
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
          "nvim-telescope/telescope.nvim",
          dependencies = { "nvim-lua/plenary.nvim" },
          config = function()
            local t = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", t.find_files)
            vim.keymap.set("n", "<leader>fg", t.live_grep)
            vim.keymap.set("n", "<leader>fb", t.buffers)
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

      }) -- end lazy.setup

      -- ── Leader key ───────────────────────────────────────────────────────────
      vim.g.mapleader = " "
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
        shell = {
          program = "${pkgs.fish}/bin/fish";
        };
      };
    };
  };

  # ── Git ──────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name  = "otakuracer";
      user.email = "aditmadjid@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
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
      default-bg          = "#1e1e2e";   # Catppuccin Mocha base
      default-fg          = "#cdd6f4";
      statusbar-bg        = "#181825";
      statusbar-fg        = "#cdd6f4";
      inputbar-bg         = "#1e1e2e";
      inputbar-fg         = "#cdd6f4";
      highlight-color     = "#f5c2e7";
      highlight-active-color = "#cba6f7";
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
      osd-color        = "#cdd6f4";       # Catppuccin text
      osd-border-color = "#1e1e2e";       # Catppuccin base

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
      #Text
      "text/plain"      = "nvim.desktop";
      "text/x-shellscript" = "nvim.desktop";
    };
  };


  gtk = {
    enable = true;
    theme = {
      name    = "catppuccin-mocha-standard-blue-dark";
      package = pkgs.catppuccin-gtk;
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders;
    };
    cursorTheme = {
      name    = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors;
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
    name    = "catppuccin-mocha-dark-cursors";
    package = pkgs.catppuccin-cursors.mochaDark;
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

  programs.home-manager.enable = true;
}
