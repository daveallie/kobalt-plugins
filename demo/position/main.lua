-- Shows what a lookup's ctx holds, for plugin authors.
local function escape(text)
  return (tostring(text):gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#39;",
  }))
end

function before_lookup(ctx)
  local position = ctx.position or {}
  local lines = {}
  if ctx.book and ctx.book.title then lines[#lines + 1] = "<b>" .. escape(ctx.book.title) .. "</b>" end
  if position.chapter then lines[#lines + 1] = escape(position.chapter) end
  if position.page and position.pages then
    lines[#lines + 1] = string.format("Page %d of %d", position.page, position.pages)
  end
  if position.percent then lines[#lines + 1] = string.format("%g%% read", position.percent) end
  return { title = ctx.word, html = "<p>" .. table.concat(lines, "<br>") .. "</p>",
           footer = "Position plugin" }
end
