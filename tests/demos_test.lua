package.path = "tests/?.lua;" .. package.path

local stub = require("stub_kobalt")

local function open(folder, setup)
  stub.reset()
  stub.install()
  if setup then setup() end
  before_lookup, book_opened, book_closed = nil, nil, nil
  dofile(folder .. "/main.lua")
  if book_opened then book_opened({ title = "Trevelyan's <Type> Tester", language = "en" }) end
end

local function lookup(word, position)
  return before_lookup({ word = word, book = { title = "Trevelyan's <Type> Tester" },
                         position = position or { percent = 12.5, page = 9, pages = 72,
                                                  chapter = "Prologue & The Firm" } })
end

local failures, total = 0, 0
local function test(name, fn)
  total = total + 1
  local ok, err = pcall(fn)
  if ok then
    print("ok   " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

local function contains(text, part)
  assert(text and text:find(part, 1, true), "expected " .. tostring(part) .. " in " .. tostring(text))
end

-- hello

test("hello_answers_every_word", function()
  open("demo/hello")
  local card = lookup("Kerning")
  assert(card.title == "Hello", tostring(card.title))
  contains(card.html, "<b>Kerning</b>")
end)

test("hello_escapes_the_word", function()
  open("demo/hello")
  contains(lookup("<i>").html, "&lt;i&gt;")
end)

-- glossary

local GLOSSARY = '{"terms":{"kerning":"Adjusting the space between two letters."}}'
local function withGlossary()
  stub.files["glossary.json"] = GLOSSARY
  stub.decoded[GLOSSARY] = { terms = { kerning = "Adjusting the space between two letters." } }
end

test("glossary_defines_known_terms", function()
  open("demo/glossary", withGlossary)
  local card = lookup("  Kerning, ")
  assert(card.title == "kerning", tostring(card.title))
  contains(card.html, "Adjusting the space between two letters.")
  assert(card.footer == "Typography glossary")
end)

test("glossary_ignores_other_words", function()
  open("demo/glossary", withGlossary)
  assert(lookup("tea") == nil)
end)

test("glossary_without_its_file_logs_once", function()
  open("demo/glossary")
  assert(lookup("kerning") == nil)
  assert(#stub.logs == 1, "expected one log line, got " .. #stub.logs)
end)

test("glossary_forgets_terms_when_the_book_closes", function()
  open("demo/glossary", withGlossary)
  book_closed()
  assert(lookup("kerning") == nil)
end)

-- position

test("position_shows_the_context", function()
  open("demo/position")
  local card = lookup("tea")
  assert(card.title == "tea", tostring(card.title))
  contains(card.html, "Page 9 of 72")
  contains(card.html, "12.5%")
  contains(card.html, "Prologue &amp; The Firm")
  contains(card.html, "Trevelyan&#39;s &lt;Type&gt; Tester")
end)

test("position_without_page_count", function()
  open("demo/position")
  local card = lookup("tea", { percent = 0 })
  contains(card.html, "0%")
  assert(not card.html:find("Page", 1, true), card.html)
end)

print(string.format("%d tests, %d failed", total, failures))
if failures > 0 then os.exit(1) end
