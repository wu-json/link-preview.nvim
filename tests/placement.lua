local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.env.SNACKS_TEST_DIR or vim.fn.stdpath("data") .. "/lazy/snacks.nvim")
local snacks = require("snacks")
local terminal = snacks.image.terminal
local placeholders = false
local cursor, request, placement
terminal.env = function()
  return { placeholders = placeholders }
end
terminal.size = function()
  return { cell_width = 10, cell_height = 20, scale = 1 }
end
terminal.set_cursor = function(pos)
  cursor = pos
end
terminal.request = function(data)
  request = data
end
-- Keep real Snacks windows, sizing, and placement; replace only terminal I/O
-- and image loading so this regression runs offline without a graphical UI.
snacks.image.setup = function() end
local image = {
  id = 1,
  file = "fixture.png",
  info = { size = { width = 1280, height = 720 }, dpi = { width = 96, height = 96 } },
  ready = function()
    return true
  end,
  failed = function()
    return false
  end,
  del = function() end,
  place = function(_, p)
    p.id = p.id or 1
  end,
}
snacks.image.image.new = function()
  return image
end
local new_placement = snacks.image.placement.new
snacks.image.placement.new = function(...)
  placement = new_placement(...)
  return placement
end
local original_renderer = snacks.image.placement.render_fallback
local style = vim.deepcopy(snacks.config.styles.snacks_image)
local preview = require("link-preview")
local cache_dir = vim.fn.tempname()
preview.url_at_cursor = function()
  return "https://youtu.be/DZC4aI5014Y"
end
preview.setup({ delay = 1, cache_dir = cache_dir })

local function check(label, above)
  local source = vim.api.nvim_get_current_win()
  vim.bo.filetype = "markdown"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn["repeat"]({ "A link to preview" }, 40))
  vim.api.nvim_win_set_cursor(0, { above and 40 or 1, 0 })
  if above then
    vim.cmd("normal! zb")
  end
  vim.cmd("redraw")
  cursor, request, placement = nil, nil, nil
  preview.schedule()
  assert(vim.wait(1000, function()
    return request and request.a == "p"
  end), label .. ": no image placement")
  local wins = placement:wins()
  assert(#wins == 1, label .. ": expected one preview window")
  local win = wins[1]
  vim.cmd("redraw")
  if placeholders then
    assert(request.U == 1 and cursor == nil, label .. ": placeholder renderer was bypassed")
  else
    local cell = vim.fn.screenpos(win, 1, 1)
    assert(cell.row > 0 and cell.col > 0, label .. ": window cell is not visible")
    assert(
      cursor[1] == cell.row,
      label .. ": image row " .. cursor[1] .. " differs from content row " .. cell.row
    )
    assert(cursor[2] + 1 == cell.col, label .. ": image column differs from content column")
  end
  assert(request.c == vim.api.nvim_win_get_width(win), label .. ": width mismatch")
  assert(request.r == vim.api.nvim_win_get_height(win), label .. ": height mismatch")
  assert(request.c >= 1 and request.c <= 40, label .. ": width exceeds configured limit")
  assert(request.r >= 1 and request.r <= 12, label .. ": height exceeds configured limit")
  local origin = vim.api.nvim_win_get_position(source)
  local pos = vim.api.nvim_win_get_position(win)
  assert(pos[1] >= origin[1] and pos[2] >= origin[2], label .. ": preview starts outside source window")
  assert(
    pos[1] + request.r + 2 <= origin[1] + vim.api.nvim_win_get_height(source),
    label .. ": preview extends below source window"
  )
  assert(
    pos[2] + request.c + 2 <= origin[2] + vim.api.nvim_win_get_width(source),
    label .. ": preview extends beyond source window"
  )
  assert(vim.deep_equal(style, snacks.config.styles.snacks_image), "global image style changed")
  assert(original_renderer == snacks.image.placement.render_fallback, "global image renderer changed")
  preview.close()
end

for _, fixture in ipairs({
  { "landscape 16:9", 1280, 720 },
  { "portrait 9:16", 720, 1280 },
  { "square", 800, 800 },
  { "ultrawide 8:1", 2400, 300 },
  { "tall 1:8", 300, 2400 },
  { "small image", 32, 24 },
}) do
  image.info.size = { width = fixture[2], height = fixture[3] }
  vim.cmd("tabonly!")
  vim.cmd("only!")
  placeholders = false
  local function scenario(label, above)
    check(fixture[1] .. ", " .. label, above)
  end
  vim.o.showtabline = 0
  scenario("hidden tabline")
  vim.o.showtabline = 2
  scenario("always-visible tabline")
  scenario("preview above cursor with visible tabline", true)
  vim.o.showtabline = 1
  scenario("automatic tabline, one tab")
  vim.cmd("tabnew")
  scenario("automatic tabline, two tabs")
  vim.cmd("vsplit")
  scenario("split with visible tabline")
  placeholders = true
  scenario("unicode placeholders with visible tabline")
end
vim.fn.delete(cache_dir, "rf")
print("Link preview image placement tests passed (42 scenarios)")
vim.cmd("qa!")
