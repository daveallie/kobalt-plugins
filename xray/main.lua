local FORMAT = "kobalt-xray/1"

local characters, byId, index = {}, {}, {}

local function normalize(word)
  word = word:lower():match("^%s*(.-)%s*$")
  local stem = word:match("^(.+)'s$") or word:match("^(.+)\226\128\153s$")
  return stem or word
end

local function escape(text)
  return (tostring(text):gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#39;",
  }))
end

local function validAt(value)
  return type(value) == "number" and value >= 0 and value <= 100
end

local function cleanEntries(list, field)
  local out = {}
  if type(list) ~= "table" then return out end
  for _, entry in ipairs(list) do
    if type(entry) == "table" and validAt(entry.at) and type(entry[field]) == "string" then
      out[#out + 1] = entry
    end
  end
  return out
end

local function earliest(entries)
  local first
  for _, entry in ipairs(entries) do
    if first == nil or entry.at < first then first = entry.at end
  end
  return first
end

local function latest(entries, position)
  local best
  for _, entry in ipairs(entries) do
    if entry.at <= position and (best == nil or entry.at >= best.at) then best = entry end
  end
  return best
end

local function addKey(key, character)
  key = normalize(key)
  if key == "" then return end
  local list = index[key]
  if list == nil then
    list = {}
    index[key] = list
  end
  if list[#list] ~= character then list[#list + 1] = character end
end

local function load(sidecar)
  local data, message = kobalt.json.decode(sidecar)
  if type(data) ~= "table" then return nil, message or "not a JSON object" end
  if data.format ~= FORMAT then return nil, "wrong_format: " .. tostring(data.format) end
  if type(data.characters) ~= "table" then return nil, "characters is not an array" end

  local duplicates = {}
  for _, raw in ipairs(data.characters) do
    if type(raw) == "table" and type(raw.id) == "string" and type(raw.name) == "string"
        and byId[raw.id] then
      if not duplicates[raw.id] then
        duplicates[raw.id] = true
        kobalt.log("X-Ray: duplicate id " .. raw.id .. ", keeping the first entry")
      end
    elseif type(raw) == "table" and type(raw.id) == "string" and type(raw.name) == "string" then
      local character = {
        id = raw.id,
        name = raw.name,
        summary = cleanEntries(raw.summary, "text"),
        relationships = {},
        appearances = cleanEntries(raw.appearances, "where"),
      }
      character.first = earliest(character.summary)
      if type(raw.relationships) == "table" then
        for _, entry in ipairs(raw.relationships) do
          if type(entry) == "table" and validAt(entry.at) and type(entry.with) == "string"
              and type(entry.text) == "string" then
            local list = character.relationships[entry.with]
            if list == nil then
              list = {}
              character.relationships[entry.with] = list
              character.relationshipOrder = character.relationshipOrder or {}
              character.relationshipOrder[#character.relationshipOrder + 1] = entry.with
            end
            list[#list + 1] = entry
          end
        end
      end
      characters[#characters + 1] = character
      byId[character.id] = character
      addKey(raw.name, character)
      for word in raw.name:gmatch("%S+") do addKey(word, character) end
      if type(raw.aliases) == "table" then
        for _, alias in ipairs(raw.aliases) do
          if type(alias) == "string" then
            addKey(alias, character)
            local bare = alias:lower():match("^the%s+(.+)$")
            if bare then addKey(bare, character) end
          end
        end
      end
    end
  end
  return true
end

local function known(character, position)
  return character.first ~= nil and character.first <= position
end

local function render(character, position)
  local parts = {}
  local summary = latest(character.summary, position)
  if summary then parts[#parts + 1] = "<p>" .. escape(summary.text) .. "</p>" end

  local lines = {}
  for _, id in ipairs(character.relationshipOrder or {}) do
    local other = byId[id]
    if other and known(other, position) then
      local entry = latest(character.relationships[id], position)
      if entry then lines[#lines + 1] = "<p>" .. escape(other.name .. " — " .. entry.text) .. "</p>" end
    end
  end
  if #lines > 0 then
    parts[#parts + 1] = "<h4>Relationships</h4>"
    for _, line in ipairs(lines) do parts[#parts + 1] = line end
  end

  local seen = latest(character.appearances, position)
  if seen then parts[#parts + 1] = "<p><b>Last seen:</b> " .. escape(seen.where) .. "</p>" end
  return table.concat(parts)
end

function book_opened(_)
  characters, byId, index = {}, {}, {}
  local sidecar = kobalt.read_sidecar("xray.json")
  if sidecar == nil then
    kobalt.log("X-Ray: no sidecar found")
    return
  end
  local ok, reason = load(sidecar)
  if not ok then
    characters, byId, index = {}, {}, {}
    kobalt.log("X-Ray: invalid sidecar: " .. tostring(reason))
  end
end

function before_lookup(ctx)
  local matches = index[normalize(ctx.word)]
  if matches == nil then return nil end
  local position = ctx.position.percent

  local shown = {}
  for _, character in ipairs(matches) do
    if known(character, position) then shown[#shown + 1] = character end
  end
  if #shown == 0 then return nil end

  local title, html
  if #shown == 1 then
    title, html = shown[1].name, render(shown[1], position)
  else
    local parts = {}
    for _, character in ipairs(shown) do
      parts[#parts + 1] = "<h4>" .. escape(character.name) .. "</h4>" .. render(character, position)
    end
    title, html = ctx.word, table.concat(parts)
  end
  return {
    title = title,
    html = html,
    footer = string.format("X-Ray · revealed up to %d%%", math.floor(position)),
  }
end
