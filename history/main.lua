local record = require("history.record")
local card = require("history.card")

function before_lookup(ctx)
  local word = ctx.word:gsub("^%s+", ""):gsub("%s+$", "")
  if word == "" then return nil end
  local page = ctx.position and ctx.position.page
  return card.build(word, record.normalize(word), record.add(word, page))
end
