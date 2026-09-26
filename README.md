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

## Development

Run the offline tests from the repository root:

```sh
nvim --headless -u NONE -l tests/run.lua
nvim --headless -u NONE -l tests/retry.lua
```

Tests require the parsers listed above. The retry test uses the installed Snacks
image cache class from `stdpath("data")/lazy/snacks.nvim`; set `SNACKS_TEST_DIR`
to use another checkout. Rendering and image conversion are stubbed; actual
image display needs a supported terminal.

CI runs these tests on pull requests and pushes to `main` that change Lua code,
tests, or CI files. The setup scripts pin Neovim, Snacks, and parser revisions.
To install the same test dependencies on Linux x86_64:

```sh
bash .github/scripts/setup-link-preview-tests.sh /tmp/link-preview-tests
export PATH="/tmp/link-preview-tests/nvim/bin:$PATH"
export SNACKS_TEST_DIR="/tmp/link-preview-tests/snacks.nvim"
```

Originally developed in [wu-json/dots](https://github.com/wu-json/dots).

## License

[MIT](LICENSE)
