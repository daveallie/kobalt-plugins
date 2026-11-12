-- Stand-in for the host's kobalt table. Tests register decoded tables per text.
local stub = { sidecar = nil, decoded = {}, logs = {}, stores = {}, files = {}, failing_set = false }

local function copy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = copy(item) end
  return result
end

-- An in-memory store with the host's get/set copy semantics.
local function store(values)
  return {
    get = function(key) return copy(values[key]) end,
    set = function(key, value)
      if stub.failing_set then return nil, "limit" end
      values[key] = copy(value)
      return true
    end,
  }
end

function stub.reset()
  stub.sidecar = nil
  stub.decoded = {}
  stub.logs = {}
  stub.files = {}
  stub.stores = { global = {}, book = {} }
  stub.failing_set = false
end

-- Starts a new book's store, keeping the shared one.
function stub.new_book()
  stub.stores.book = {}
  kobalt.book_store = store(stub.stores.book)
end

-- Lets require load modules from a plugin's own folder, as the host does,
-- and forgets modules an earlier test loaded. `folder` is a path such as
-- demo/history; modules are named from inside it, such as history.record.
function stub.use_plugin(folder)
  package.path = folder .. "/?.lua;" .. package.path
  local id = folder:match("([^/]+)$")
  for name in pairs(package.loaded) do
    if name:match("^" .. id .. "%.") then package.loaded[name] = nil end
  end
end

function stub.install()
  kobalt = {
    read_sidecar = function(suffix)
      assert(suffix == "xray.json", "unexpected sidecar suffix " .. tostring(suffix))
      return stub.sidecar
    end,
    read_file = function(path) return stub.files[path] end,
    log = function(message) stub.logs[#stub.logs + 1] = message end,
    store = store(stub.stores.global),
    book_store = store(stub.stores.book),
    json = {
      decode = function(text)
        local value = stub.decoded[text]
        if value == nil then return nil, "parse error" end
        return value
      end,
    },
  }
end

return stub
