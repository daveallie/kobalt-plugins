-- Stand-in for the host's kobalt table. Tests register decoded tables per text.
local stub = { sidecar = nil, decoded = {}, logs = {} }

function stub.reset()
  stub.sidecar = nil
  stub.decoded = {}
  stub.logs = {}
end

function stub.install()
  kobalt = {
    read_sidecar = function(suffix)
      assert(suffix == "xray.json", "unexpected sidecar suffix " .. tostring(suffix))
      return stub.sidecar
    end,
    read_file = function() return nil end,
    log = function(message) stub.logs[#stub.logs + 1] = message end,
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
