+++
title = "Tailwind IntelliSense in Elm: A NeoVim Recipe"
description = "Quick setup guide for getting Tailwind CSS autocomplete and hover working with Elm in NeoVim"
tags = ["elm", "neovim", "tailwind", "lsp", "recipe"]
date = "2025-07-04"
draft = false
+++

If you're using Elm with Tailwind CSS in NeoVim, you've probably noticed that IntelliSense doesn't work out of the box. Here's a quick recipe to fix that.

## The Problem

Tailwind's LSP doesn't recognize Elm's syntax for CSS classes. When you write:

```elm
div [ class "bg-blue-500 text-white p-4" ] [ text "Hello" ]
```

You get no autocomplete, no validation, and no hover documentation for your Tailwind classes.

## The Solution

### My Setup (LazyVim)

Here's what works for me using LazyVim. If you're using a different NeoVim distribution, your mileage may vary:

```lua
{
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        filetypes_include = { "elm" },
        -- exclude a filetype from the default_config
        filetypes_exclude = {},
      },
    },
    setup = {
      tailwindcss = function(_, opts)
        local tw = LazyVim.lsp.get_raw_config("tailwindcss")
        opts.filetypes = opts.filetypes or {}

        -- Add default filetypes
        vim.list_extend(opts.filetypes, tw.default_config.filetypes)

        -- Remove excluded filetypes
        opts.filetypes = vim.tbl_filter(function(ft)
          return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
        end, opts.filetypes)

        opts.settings = {
          tailwindCSS = {
            includeLanguages = {
              elm = "html",
            },
            experimental = {
              classRegex = {
                { [[\bclass[\s(<|]+"([^"]*)"]] },
                { [[\bclass[\s(]+"[^"]*"\s+"([^"]*)"]] },
                { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" ([^"]*)"]] },
                { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"]] },
                { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"]] },
                { [[\bclassList[\s\[\(]+"([^"]*)"]] },
                { [[\bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"]] },
                { [[\bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"]] },
              },
            },
          },
        }

        -- Add additional filetypes
        vim.list_extend(opts.filetypes, opts.filetypes_include or {})
      end,
    },
  },
}
```

### For Vanilla NeoVim

If you're using plain nvim-lspconfig, I'm guessing you'd need something like this (but I'm mostly spitballing here - you get the idea):

```lua
require('lspconfig').tailwindcss.setup({
  filetypes = {
    'html', 'css', 'javascript', 'typescript', 'react', 'vue', 'svelte', 'elm'
  },
  settings = {
    tailwindCSS = {
      includeLanguages = {
        elm = "html",
      },
      experimental = {
        classRegex = {
          { [[\bclass[\s(<|]+"([^"]*)"]] },
          { [[\bclass[\s(]+"[^"]*"\s+"([^"]*)"]] },
          { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" ([^"]*)"]] },
          { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"]] },
          { [[\bclass[\s<|]+"[^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" [^"]*"\s*\+{2}\s*" ([^"]*)"]] },
          { [[\bclassList[\s\[\(]+"([^"]*)"]] },
          { [[\bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"]] },
          { [[\bclassList[\s\[\(]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"[^"]*",\s[^\)]+\)[\s\[\(,]+"([^"]*)"]] },
        },
      },
    },
  },
})
```

## What's Happening

Both configs do the same thing with different syntax:

1. **Add `elm` to filetypes** - Tells Tailwind LSP to activate for Elm files
2. **`includeLanguages = { elm = "html" }`** - Treats Elm syntax like HTML for class detection
3. **`classRegex` patterns** - Regular expressions that match Elm's various class syntax patterns:
   - `class "bg-blue-500"` - Basic class attribute
   - `class "text-lg" ++ " font-bold"` - String concatenation
   - `classList [ ("active", isActive) ]` - Conditional classes

## The Result

Now you get full Tailwind IntelliSense in your Elm files:

- Autocomplete for class names
- Hover documentation
- Color previews
- Validation warnings for invalid classes

## Full Setup

My complete NeoVim config (including this setup) is available at [github.com/cekrem/dotfiles](https://github.com/cekrem/dotfiles) if you want to see how it fits into a larger LazyVim configuration.

This small addition makes Elm + Tailwind development much more pleasant. No more guessing at class names or checking the docs constantly.

