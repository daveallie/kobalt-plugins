-- Reads a data file from the plugin's own folder when the book opens.
local terms = {}

local function escape(text)
  return (tostring(text):gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#39;",
  }))
end

function book_opened(_)
  terms = {}
  local text = kobalt.read_file("glossary.json")
  local data, message = nil, "missing"
  if text then data, message = kobalt.json.decode(text) end
  if type(data) ~= "table" or type(data.terms) ~= "table" then
    kobalt.log("glossary: cannot read glossary.json: " .. tostring(message))
    return
  end
  for term, meaning in pairs(data.terms) do
    if type(term) == "string" and type(meaning) == "string" then terms[term:lower()] = meaning end
  end
end

function book_closed()
  terms = {}
end

function before_lookup(ctx)
  local word = ctx.word:lower():gsub("^[%s%p]+", ""):gsub("[%s%p]+$", "")
  local meaning = terms[word]
  if not meaning then return nil end
  return { title = word, html = "<p>" .. escape(meaning) .. "</p>", footer = "Typography glossary" }
end
