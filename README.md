# link-preview.nvim

Markdown link previews for Neovim, powered by Snacks images, Open Graph metadata,
and YouTube thumbnails. Pause the cursor on a link in normal mode to see its preview.

## Requirements

- Neovim 0.10+ (CI tests with 0.11.5).
- [snacks.nvim](https://github.com/folke/snacks.nvim) with image support enabled.
- `curl`, ImageMagick, and a terminal supported by Snacks image rendering.
- The `html`, `markdown`, and `markdown_inline` Tree-sitter parsers.

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  {
    "wu-json/link-preview.nvim",
    main = "link-preview",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    opts = {},
  },
  {
    "folke/snacks.nvim",
    opts = {
      image = {
        enabled = true,
        -- Optional: also resolve YouTube URLs used in Markdown image embeds.
        resolve = function(_, src)
          return require("link-preview").resolve_image(nil, src)
        end,
      },
    },
  },
}
```

Install the required parsers through your Tree-sitter setup. For configurations
using `nvim-treesitter`'s `ensure_installed` option, include `"html"`, `"markdown"`,
and `"markdown_inline"`.

With another plugin manager, install this repository and Snacks, enable Snacks
images, then call `require("link-preview").setup({})`.

## Configuration

All options are optional. Defaults:

```lua
require("link-preview").setup({
  filetypes = { "markdown", "markdown.mdx" },
  delay = 200,          -- milliseconds before showing a preview
  max_width = 40,       -- columns
  max_height = 12,      -- rows
  ttl = 3600,           -- successful metadata cache lifetime, seconds
  failure_ttl = 60,    -- failed preview cache lifetime, seconds
  max_entries = 128,
  -- cache_dir = "/path/to/cache", -- defaults to a per-user temporary directory
})
```

Previewing a link fetches its page and image. YouTube links use thumbnails directly.
Metadata is cached in memory and on disk. Links without an image show a text
fallback. Moving away closes the preview; `require("link-preview").close()` also
closes it manually.

`require("link-preview").resolve_image(_, src)` resolves YouTube thumbnails and
returns `nil` for other sources, allowing Snacks to resolve them normally.

## License

[MIT](LICENSE)
