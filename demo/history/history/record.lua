-- Counts lookups per word in the book's store and the shared store.
local record = {}

local warned = false

local function key(word)
  return "word:" .. word
end

local function save(store, name, value)
  local ok, message = store.set(name, value)
  if not ok and not warned then
    warned = true
    kobalt.log("history: could not save a lookup: " .. tostring(message))
  end
end

function record.normalize(word)
  return (word:gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

-- Adds one lookup of `word` on `page` and returns the updated counts.
function record.add(word, page)
  local name = key(record.normalize(word))
  local book = kobalt.book_store.get(name) or { count = 0 }
  book.count = book.count + 1
  if book.first == nil and type(page) == "number" then book.first = page end
  local all = (kobalt.store.get(name) or 0) + 1
  save(kobalt.book_store, name, book)
  save(kobalt.store, name, all)
  return { book = book.count, first = book.first, all = all }
end

return record
