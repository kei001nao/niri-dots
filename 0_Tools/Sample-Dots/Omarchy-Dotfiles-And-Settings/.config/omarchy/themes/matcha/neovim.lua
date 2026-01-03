return {
    {
        "bjarneo/aether.nvim",
        name = "aether",
        priority = 1000,
        opts = {
            disable_italics = false,
            colors = {
                -- Monotone shades (base00-base07)
                base00 = "#181911", -- Default background
                base01 = "#818462", -- Lighter background (status bars)
                base02 = "#181911", -- Selection background
                base03 = "#818462", -- Comments, invisibles
                base04 = "#deded3", -- Dark foreground
                base05 = "#f3f4f1", -- Default foreground
                base06 = "#f3f4f1", -- Light foreground
                base07 = "#deded3", -- Light background

                -- Accent colors (base08-base0F)
                base08 = "#c09559", -- Variables, errors, red
                base09 = "#d9b582", -- Integers, constants, orange
                base0A = "#cfc877", -- Classes, types, yellow
                base0B = "#cdb56a", -- Strings, green
                base0C = "#93cd6a", -- Support, regex, cyan
                base0D = "#b5cf68", -- Functions, keywords, blue
                base0E = "#b8d68f", -- Keywords, storage, magenta
                base0F = "#e9e5b9", -- Deprecated, brown/yellow
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            -- Enable hot reload
            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
