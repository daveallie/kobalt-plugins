package.path = "tests/?.lua;xray/?.lua;" .. package.path

local stub = require("stub_kobalt")

local function sample()
  return {
    format = "kobalt-xray/1",
    book = { title = "The Fifth Tide" },
    characters = {
      {
        id = "maren", name = "Maren Holt",
        aliases = { "Maren", "Holt", "the Harbourmaster" },
        summary = {
          { at = 0, text = "Harbourmaster of Grey Quay; lost her ship in book 3." },
          { at = 41.5, text = "Harbourmaster, now secretly allied with the Tidewardens." },
        },
        relationships = {
          { at = 0, with = "corin", text = "Estranged brother" },
          { at = 62, with = "corin", text = "Reconciled brother" },
        },
        appearances = {
          { at = 0, where = "Book 4, ch. 30" },
          { at = 18, where = "Ch. 4" },
        },
      },
      {
        id = "corin", name = "Corin Holt", aliases = { "Corin" },
        summary = { { at = 0, text = "Maren's brother, a pilot." } },
      },
    },
  }
end

local function open(data)
  stub.reset()
  stub.install()
  if data ~= nil then
    stub.sidecar = "sidecar-text"
    stub.decoded["sidecar-text"] = data
  end
  dofile("xray/main.lua")
  book_opened({ title = "The Fifth Tide", language = "en" })
end

local function lookup(word, percent)
  return before_lookup({ word = word, position = { percent = percent } })
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
local function lacks(text, part)
  assert(not text:find(part, 1, true), "unexpected " .. part .. " in " .. text)
end

test("before_first_mention", function()
  local data = sample()
  data.characters[1].summary = { { at = 41.5, text = "Late." } }
  open(data)
  assert(lookup("Maren", 41.4) == nil)
  assert(lookup("Maren", 41.5) ~= nil)
end)

test("summary_boundary", function()
  open(sample())
  local early = lookup("Maren", 41.4)
  contains(early.html, "lost her ship in book 3.")
  lacks(early.html, "Tidewardens")
  local late = lookup("Maren", 41.5)
  contains(late.html, "Tidewardens")
  lacks(late.html, "lost her ship")
  assert(late.title == "Maren Holt")
end)

test("relationship_latest", function()
  open(sample())
  local before = lookup("Maren", 61.9)
  contains(before.html, "<h4>Relationships</h4>")
  contains(before.html, "<p>Corin Holt — Estranged brother</p>")
  lacks(before.html, "Reconciled")
  contains(lookup("Maren", 62).html, "<p>Corin Holt — Reconciled brother</p>")
end)

test("relationship_hidden_until_other_known", function()
  local data = sample()
  data.characters[2].summary = { { at = 50, text = "A pilot." } }
  open(data)
  local card = lookup("Maren", 49)
  lacks(card.html, "Relationships")
  lacks(card.html, "Estranged")
  contains(lookup("Maren", 50).html, "Estranged brother")
end)

test("relationship_to_unknown_id_is_hidden", function()
  local data = sample()
  data.characters[1].relationships = { { at = 0, with = "nobody", text = "Rival" } }
  open(data)
  lacks(lookup("Maren", 90).html, "Relationships")
end)

test("last_seen", function()
  open(sample())
  contains(lookup("Maren", 17.9).html, "<p><b>Last seen:</b> Book 4, ch. 30</p>")
  contains(lookup("Maren", 18).html, "<p><b>Last seen:</b> Ch. 4</p>")
  local data = sample()
  data.characters[1].appearances = { { at = 30, where = "Ch. 9" } }
  open(data)
  lacks(lookup("Maren", 29).html, "Last seen")
end)

test("aliases_and_case", function()
  open(sample())
  for _, word in ipairs({ "holt", "HARBOURMASTER", "Maren", "the harbourmaster", "Maren Holt" }) do
    local card = lookup(word, 10)
    assert(card, word)
    contains(card.html, "Harbourmaster of Grey Quay")
  end
  assert(lookup("Tidewardens", 10) == nil)
  assert(lookup("the", 10) == nil)
end)

test("punctuation_quotes_and_dashes", function()
  open(sample())
  for _, word in ipairs({ "Maren,", "“Maren”", "Maren—", "‘Maren’", "–Maren.", "(Maren’s)" }) do
    assert(lookup(word, 10), word)
  end
end)

test("timed_alias", function()
  local data = sample()
  data.characters[2].aliases = { "Corin", { text = "the Grey Pilot", at = 75 } }
  open(data)
  assert(lookup("Grey Pilot", 74.9) == nil)
  assert(lookup("the Grey Pilot", 74.9) == nil)
  local card = lookup("Grey Pilot", 75)
  assert(card and card.title == "Corin Holt")
  assert(lookup("the Grey Pilot", 80).title == "Corin Holt")
  assert(lookup("Corin", 10).title == "Corin Holt")
end)

test("timed_alias_waits_for_the_character", function()
  local data = sample()
  data.characters[2].summary = { { at = 50, text = "A pilot." } }
  data.characters[2].aliases = { { text = "Pilot", at = 20 } }
  open(data)
  assert(lookup("Pilot", 30) == nil)
  assert(lookup("Pilot", 50).title == "Corin Holt")
end)

test("timed_alias_does_not_hide_a_plain_key", function()
  local data = sample()
  data.characters[1].aliases = { "Maren", { text = "Holt", at = 90 } }
  open(data)
  assert(lookup("Holt", 10), "the surname from the name was hidden")
  local skipped = sample()
  skipped.characters[1].aliases = { { text = "Gull", at = "late" }, { at = 5 }, "Maren" }
  open(skipped)
  assert(lookup("Gull", 99) == nil)
  assert(lookup("Maren", 10))
end)

test("possessive", function()
  open(sample())
  assert(lookup("Maren's", 10))
end)

test("curly_possessive", function()
  open(sample())
  assert(lookup("Maren’s", 10))
end)

test("several_matches", function()
  local data = sample()
  data.characters[2].aliases = { "Corin", "Holt" }
  open(data)
  local card = lookup("Holt", 10)
  assert(card.title == "Holt")
  contains(card.html, "<h4>Maren Holt</h4>")
  contains(card.html, "<h4>Corin Holt</h4>")
  assert(select(2, card.html:gsub("<h4>Maren Holt</h4>", "")) == 1)
end)

test("several_matches_skip_unknown", function()
  local data = sample()
  data.characters[2].aliases = { "Corin", "Holt" }
  data.characters[2].summary = { { at = 70, text = "Later." } }
  open(data)
  local card = lookup("Holt", 10)
  assert(card.title == "Maren Holt")
  lacks(card.html, "<h4>")
end)

test("footer", function()
  open(sample())
  assert(lookup("Maren", 41.9).footer == "X-Ray · revealed up to 41%")
  assert(lookup("Maren", 100).footer == "X-Ray · revealed up to 100%")
end)

test("escapes_sidecar_text", function()
  local data = sample()
  data.characters[1].name = "Maren <b>&"
  data.characters[1].aliases = { "Maren" }
  data.characters[1].summary = { { at = 0, text = "<script>x</script> & \"q\"" } }
  data.characters[1].appearances = { { at = 0, where = "<i>Ch. 1</i>" } }
  data.characters[2].name = "<Corin>"
  open(data)
  local card = lookup("Maren", 10)
  lacks(card.html, "<script>")
  contains(card.html, "&lt;script&gt;x&lt;/script&gt; &amp; &quot;q&quot;")
  contains(card.html, "&lt;i&gt;Ch. 1&lt;/i&gt;")
  contains(card.html, "&lt;Corin&gt; — Estranged brother")
  local several = sample()
  several.characters[1].name = "<M> Holt"
  several.characters[2].aliases = { "Corin", "Holt" }
  open(several)
  contains(lookup("Holt", 10).html, "<h4>&lt;M&gt; Holt</h4>")
end)

test("missing_sidecar", function()
  open(nil)
  assert(lookup("Maren", 50) == nil)
  assert(lookup("Holt", 50) == nil)
  assert(#stub.logs == 1, #stub.logs)
end)

test("invalid_sidecar", function()
  stub.reset()
  stub.install()
  stub.sidecar = "not json"
  dofile("xray/main.lua")
  book_opened({ title = "x" })
  assert(lookup("Maren", 50) == nil)
  assert(lookup("Holt", 50) == nil)
  assert(#stub.logs == 1, #stub.logs)
end)

test("wrong_format", function()
  local data = sample()
  data.format = "kobalt-xray/2"
  open(data)
  assert(lookup("Maren", 50) == nil)
  assert(#stub.logs == 1, #stub.logs)
end)

test("malformed_structure_is_invalid", function()
  open({ format = "kobalt-xray/1", characters = "nope" })
  assert(lookup("Maren", 50) == nil)
  assert(#stub.logs == 1)
end)

test("unknown_fields_ignored_and_bad_entries_skipped", function()
  local data = sample()
  data.extra = true
  data.characters[1].mood = "grim"
  data.characters[1].summary[3] = { at = "x", text = 5 }
  data.characters[3] = "junk"
  open(data)
  contains(lookup("Maren", 10).html, "lost her ship")
end)

test("duplicate_id_keeps_first_and_logs_once", function()
  local data = sample()
  data.characters[3] = { id = "maren", name = "Other", aliases = { "Maren" },
    summary = { { at = 0, text = "Impostor." } } }
  data.characters[4] = { id = "maren", name = "Third", summary = { { at = 0, text = "Again." } } }
  open(data)
  assert(#stub.logs == 1, #stub.logs)
  local card = lookup("Maren", 10)
  assert(card.title == "Maren Holt")
  lacks(card.html, "Impostor")
  assert(lookup("Other", 10) == nil)
end)

test("book_reopened_resets_state", function()
  open(sample())
  assert(lookup("Maren", 10))
  stub.sidecar = nil
  book_opened({ title = "other" })
  assert(lookup("Maren", 10) == nil)
end)

print(string.format("%d tests, %d failed", total, failures))
if failures > 0 then os.exit(1) end
