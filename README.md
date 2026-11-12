# kobalt-plugins

[![CI](https://github.com/daveallie/kobalt-plugins/actions/workflows/ci.yml/badge.svg)](https://github.com/daveallie/kobalt-plugins/actions/workflows/ci.yml)

Plugins for [Kobalt](https://github.com/nicoverbruggen/kobalt), the Qt e-reader. They are Lua 5.4 plugins that use Kobalt's plugin API (version 1).

## X-Ray

Hold a character's name while reading. The dictionary opens as usual, and a dot on its dictionary chooser shows that X-Ray has an answer; choose X-Ray in the chooser to see a spoiler-safe card with a one-line summary, relationships and where the character was last seen, limited to your reading position. The data comes from a sidecar JSON file next to the book.

### Install

Copy the `xray/` folder, which holds `plugin.json` and `main.lua`, into the plugin folder of your platform:

| Platform | Plugin folder |
| --- | --- |
| Kobo | `.adds/kobalt/plugins/xray/` on user storage |
| Desktop | `plugins/xray/` in the Kobalt profile folder |

Android does not support sidecars, because imported books have no file beside them, so X-Ray does nothing there.

Removing the folder removes the plugin. Kobalt reads plugins when a book opens.

### Sidecar location

Put the sidecar beside the book, named after the book file without its final extension, plus `.xray.json`. For `Wolf Hall.epub`, the sidecar is `Wolf Hall.xray.json`. Only the last extension is replaced, so for a Kobo store book such as `Wolf Hall.kepub.epub`, the sidecar is `Wolf Hall.kepub.xray.json`.

Without a sidecar, or with an invalid one, X-Ray adds nothing to the chooser. The reason is written once to Kobalt's diagnostic log.

### Sidecar format

`example.xray.json` in `xray/` is a complete example, and `xray/sidecar.schema.json` is its JSON Schema (draft 2020-12).

```json
{
  "format": "kobalt-xray/1",
  "book": { "title": "The Fifth Tide", "series": "Saltmarsh", "number": 5 },
  "characters": [{
    "id": "maren",
    "name": "Maren Holt",
    "aliases": ["Maren", "Holt", "the Harbourmaster"],
    "summary": [
      { "at": 0,    "text": "Harbourmaster of Grey Quay; lost her ship in book 3." },
      { "at": 41.5, "text": "Harbourmaster, now secretly allied with the Tidewardens." }
    ],
    "relationships": [
      { "at": 0,  "with": "corin", "text": "Estranged brother" },
      { "at": 62, "with": "corin", "text": "Reconciled brother" }
    ],
    "appearances": [
      { "at": 0,  "where": "Book 4, ch. 30" },
      { "at": 18, "where": "Ch. 4" }
    ]
  }]
}
```

- `format` must be exactly `kobalt-xray/1`. Any other value makes the file invalid.
- `id` is unique within the file, and `with` names another character's `id`.
- `at` is a position in this book, from 0 to 100, as a percentage of its words. A fact shows once your position reaches `at`.
- An alias is a string, or an object `{ "text": "the Grey Pilot", "at": 75 }`. A string matches as soon as the character is known. An object matches only once your position also reaches its own `at`.
- `book` is informational. Unknown fields are ignored.

What shows at your position:

- A character is unknown until the `at` of its earliest `summary` entry is reached. Before then, X-Ray adds nothing for that name.
- The summary is the entry with the greatest `at` that is reached.
- Each relationship shows the latest reached entry for that person. It stays hidden until the other character is known.
- Last seen is the latest reached `appearances` entry. The section is left out when none is reached.
- Matching ignores case, punctuation, straight and curly quotes and dashes at either end of the selection, and a trailing `'s` or `’s`. It compares the selected text with the full name, each word of the name and each alias.
- Several matches, such as two characters called Holt, stack in one card titled with the selected word, each under its name.
- The footer reads "X-Ray · revealed up to N%", with N rounded down.

A long press selects one word, so each alias matches only as a whole, or without a leading "the". An alias such as "Captain Maren" does not match "Captain" or "Maren" alone. List single-word aliases too: first name, surname, nickname and title.

Every word of `name` is indexed as well, so a name like "The Lord of Light" also answers "the" and "of". Give such a character a plain `name` and put the epithet in `aliases`.

### Secret identities

`name` and plain string aliases work from the moment a character is known, so they must be names that a reader can already link to that character when it is introduced. A relationship line shows the other character's `name`, so every `name` must be free of spoilers too.

When the book later reveals that two names are one person, such as a masked stranger who turns out to be Corin, do one of these:

- Keep a separate character entry for the stranger until the reveal, and add the connection to Corin's entries at the `at` of the reveal.
- Or give Corin an alias object with the reveal's `at`, such as `{ "text": "Stranger", "at": 75 }`. Before 75, holding "Stranger" does not show Corin.

Use no JSON `null` anywhere. Kobalt decodes it to nothing, so a key with `null` is missing and the entries after a `null` in an array are dropped. A duplicate `id` is logged once and the first entry is kept.

All text from the sidecar is escaped, so it shows as written.

### The `at` rule

Set `at` to the percentage at the **end of the chapter** in which a fact is revealed, not where it first appears. The fact then shows when you finish that chapter. This absorbs small differences between an AI's word count and Kobalt's, and Kobalt's estimate of the position inside a chapter.

Knowledge from earlier books in a series goes in at `at: 0`. Every character needs a summary at the point where it is introduced.

### Validate a sidecar

Any JSON Schema validator that supports draft 2020-12 can check a sidecar against `xray/sidecar.schema.json`. For example, with `check-jsonschema`:

```sh
check-jsonschema --schemafile xray/sidecar.schema.json "Wolf Hall.xray.json"
```

### Suggested AI prompt

Give this to an AI together with the book text (or notes on each chapter), and save the answer as the sidecar.

```text
Write an X-Ray sidecar for the attached book as JSON only, with no other text.

Use this structure:
{
  "format": "kobalt-xray/1",
  "book": { "title": "...", "series": "...", "number": 1 },
  "characters": [{
    "id": "short-lowercase-id",
    "name": "Full name",
    "aliases": ["every other way the book names this person, such as a first name, surname, title or nickname"],
    "summary": [{ "at": 0, "text": "One sentence on who this is." }],
    "relationships": [{ "at": 0, "with": "other-character-id", "text": "Short description, such as 'Estranged brother'" }],
    "appearances": [{ "at": 0, "where": "Ch. 1" }]
  }]
}

Rules:
- "at" is a percentage from 0 to 100 of the book by word count. It is the percentage at the END of the chapter in which a fact is revealed, never the point inside the chapter where it appears. Round up to the end of that chapter.
- Everything a reader knows from earlier books in a series goes in at "at": 0.
- Every character needs a summary entry at the end of the chapter that introduces them. Their earliest summary decides when they become known, so never put a summary earlier than the introduction.
- Add a later summary entry whenever something important about the character is revealed, and write it as the full picture at that point, not as a change note.
- A relationship is a person's relation to another character in the file. Add a new entry with a later "at" when the relationship changes. Use the other character's "id" in "with".
- "appearances" lists where the character was seen, one entry per chapter that matters. "where" names the chapter.
- Never reveal anything before its "at". Do not mention events or identities that come later in a summary, relationship or appearance written for an earlier "at".
- Keep texts short, plain and free of markup.
- A long press selects a single word, and an alias only matches as a whole. List single-word aliases (first name, surname, nickname, title) as well as longer ones such as "Captain Maren". Keep "name" plain, and put epithets in "aliases".
- "name" and every plain string alias must be names the reader can link to the character at the point of introduction. "name" also appears in other characters' relationships, so it must never give away a secret.
- A secret identity stays a separate character until the reveal. Alternatively, write the revealing alias as an object, { "text": "the alias", "at": <reveal percentage> }, so it matches only from the reveal on.
- Never use null in the JSON.
- Include only characters that matter to the story. Make every "id" unique.
```

### Tests

The tests need a Lua 5.4 interpreter and run against a stub of Kobalt's API, with no Kobalt build:

```sh
make test
```

Set `LUA` when the interpreter has another name, for example `make test LUA=lua`.

## Lookup history

Shows how often you have looked up a word: how many times in this book, the page of the first lookup, and how many times in all books. Words count the same in any letter case. Every lookup adds Lookup history to the dictionary chooser; choose it to see the counts.

Copy the `history/` folder, with `plugin.json`, `main.lua` and its `history/` modules, into the plugin folder of your platform, as for X-Ray. It works on Android too, in `plugins/history/` in the app's external files folder.

It shows how a plugin splits its code into modules with `require` and keeps data with `kobalt.store`, shared by all books, and `kobalt.book_store`, kept for each book. Kobalt saves that data outside the plugin folder, so replacing the folder for an upgrade keeps the counts:

| Platform | Plugin data folder |
| --- | --- |
| Kobo | `.adds/kobalt/plugin-data/history/` on user storage |
| Android | `plugin-data/history/` in the app's external files folder |
| Desktop | `plugin-data/history/` in the Kobalt profile folder |

Settings > System > Plugins in Kobalt shows whether a plugin is running, turns it off, and deletes its saved data.

## Development

CI runs the tests on Lua 5.4.9, the version Kobalt embeds, checks that every JSON file parses and validates `xray/example.xray.json` against the schema. Locally:

```sh
make test LUA=/path/to/lua5.4   # Lua tests only
make check LUA=/path/to/lua5.4  # tests, JSON parse check and schema check (needs python3 and npx)
```
