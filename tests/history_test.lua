package.path = "tests/?.lua;" .. package.path

local stub = require("stub_kobalt")

local function open()
  stub.reset()
  stub.install()
  stub.use_plugin("history")
  dofile("history/main.lua")
end

local function lookup(word, page)
  return before_lookup({ word = word, position = { page = page, pages = 300, percent = 4 } })
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

test("first_lookup", function()
  open()
  local card = lookup("Tide", 12)
  assert(card.title == "Tide", tostring(card.title))
  contains(card.html, "Looked up 1 time in this book, first on page 12.")
  contains(card.html, "1 time in all books.")
end)

test("second_lookup", function()
  open()
  lookup("Tide", 12)
  local card = lookup("Tide", 40)
  contains(card.html, "2 times in this book, first on page 12")
  contains(card.html, "2 times in all books")
end)

test("another_book", function()
  open()
  lookup("Tide", 12)
  lookup("Tide", 40)
  stub.new_book()
  local card = lookup("Tide", 7)
  contains(card.html, "1 time in this book")
  contains(card.html, "3 times in all books")
end)

test("case_and_space", function()
  open()
  lookup("Tide", 12)
  local card = lookup("  tIDE ", 13)
  contains(card.html, "2 times in this book")
end)

test("escapes_html", function()
  open()
  local card = lookup("<b>", 3)
  contains(card.html, "&lt;b&gt;")
  assert(not card.html:find("<b>", 1, true), card.html)
end)

test("failed_set_still_answers", function()
  open()
  stub.failing_set = true
  local card = lookup("Tide", 12)
  assert(card and card.title == "Tide")
  lookup("Tide", 13)
  assert(#stub.logs == 1, "expected one log line, got " .. #stub.logs)
end)

print(string.format("%d tests, %d failed", total, failures))
if failures > 0 then os.exit(1) end
