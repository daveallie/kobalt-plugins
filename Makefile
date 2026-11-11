LUA ?= lua5.4

.PHONY: test
test:
	$(LUA) tests/xray_test.lua
