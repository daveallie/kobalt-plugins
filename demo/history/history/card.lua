-- Builds the card shown in the dictionary sheet.
local card = {}

local function escape(text)
  return (tostring(text):gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#39;",
  }))
end

local function times(count)
  return count == 1 and "1 time" or (count .. " times")
end

-- `key` is the case-folded form the counts are kept under.
function card.build(word, key, counts)
  local book = "Looked up " .. times(counts.book) .. " in this book"
  if counts.first then book = book .. ", first on page " .. counts.first end
  return {
    title = word,
    html = "<p>" .. escape(book) .. ".</p><p>" .. escape(times(counts.all)) .. " in all books.</p>"
      .. "<p>Counted as <i>" .. escape(key) .. "</i> in any letter case.</p>",
    footer = "Lookup history",
  }
end

return card
