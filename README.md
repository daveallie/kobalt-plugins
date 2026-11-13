# kobalt-plugins

[![CI](https://github.com/daveallie/kobalt-plugins/actions/workflows/ci.yml/badge.svg)](https://github.com/daveallie/kobalt-plugins/actions/workflows/ci.yml)

Plugins for [Kobalt](https://github.com/nicoverbruggen/kobalt), the Qt e-reader. They are Lua 5.4 plugins that use Kobalt's plugin API (version 1).

> [!WARNING]
> Kobalt's plugin system is a proof of concept and has not been officially accepted into Kobalt yet (see [the discussion](https://github.com/nicoverbruggen/kobalt/discussions/157)). The plugin API may change or be dropped, and these plugins only run on a Kobalt build that includes it.

## Plugins

### [X-Ray](xray/)

Hold a character's name while reading to see a spoiler-safe card with a one-line summary, relationships and where the character was last seen, limited to your reading position. The data comes from a sidecar JSON file next to the book. See [`xray/README.md`](xray/README.md) to install it and write sidecars.

### [Demos](demo/)

Small example plugins that each show part of the plugin API, to read and copy rather than use: `hello`, `glossary`, `position` and `history`. See [`demo/README.md`](demo/README.md) for what each one shows and how to try it.

## Tests

The tests, for X-Ray and the demos, need a Lua 5.4 interpreter and run against a stub of Kobalt's API in `tests/stub_kobalt.lua`, with no Kobalt build:

```sh
make test
```

Set `LUA` when the interpreter has another name, for example `make test LUA=lua`.

`make check` also checks that every JSON file parses and validates `xray/example.xray.json` against the schema, which needs `python3` and `npx`:

```sh
make check LUA=/path/to/lua5.4
```

CI runs `make test` on Lua 5.4.9, the version Kobalt embeds, plus the same JSON and schema checks.
