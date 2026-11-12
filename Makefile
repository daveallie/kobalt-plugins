LUA ?= lua5.4

.PHONY: test json schema check
test:
	$(LUA) tests/xray_test.lua
	$(LUA) tests/history_test.lua
	$(LUA) tests/demos_test.lua

json:
	find . -name '*.json' -not -path './.git/*' -print0 | xargs -0 -n1 python3 -m json.tool > /dev/null

schema:
	npx --yes ajv-cli@5.0.0 validate --spec=draft2020 -s xray/sidecar.schema.json -d xray/example.xray.json

check: test json schema
