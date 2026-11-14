# X-Ray

Hold a character's name while reading. The dictionary opens as usual, and a dot on its dictionary chooser shows that X-Ray has an answer; choose X-Ray in the chooser to see a spoiler-safe card with a one-line summary, relationships and where the character was last seen, limited to your reading position. The data comes from a sidecar JSON file next to the book.

## Install

Copy this `xray/` folder, which holds `plugin.json` and `main.lua`, into the plugin folder of your platform:

| Platform | Plugin folder |
| --- | --- |
| Kobo | `.adds/kobalt/plugins/xray/` on user storage |
| Desktop | `plugins/xray/` in the Kobalt profile folder |

Android does not support sidecars, because imported books have no file beside them, so X-Ray does nothing there.

Removing the folder removes the plugin. Kobalt reads plugins when a book opens.

## Sidecar location

Put the sidecar beside the book, named after the book file without its final extension, plus `.xray.json`. For `Wolf Hall.epub`, the sidecar is `Wolf Hall.xray.json`. Only the last extension is replaced, so for a Kobo store book such as `Wolf Hall.kepub.epub`, the sidecar is `Wolf Hall.kepub.xray.json`.

Without a sidecar, or with an invalid one, X-Ray adds nothing to the chooser. The reason is written once to Kobalt's diagnostic log.

## Sidecar format

[`example.xray.json`](example.xray.json) is a complete example, and [`sidecar.schema.json`](sidecar.schema.json) is its JSON Schema (draft 2020-12).

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

## Secret identities

`name` and plain string aliases work from the moment a character is known, so they must be names that a reader can already link to that character when it is introduced. A relationship line shows the other character's `name`, so every `name` must be free of spoilers too.

When the book later reveals that two names are one person, such as a masked stranger who turns out to be Corin, do one of these:

- Keep a separate character entry for the stranger until the reveal, and add the connection to Corin's entries at the `at` of the reveal.
- Or give Corin an alias object with the reveal's `at`, such as `{ "text": "Stranger", "at": 75 }`. Before 75, holding "Stranger" does not show Corin.

Use no JSON `null` anywhere. Kobalt decodes it to nothing, so a key with `null` is missing and the entries after a `null` in an array are dropped. A duplicate `id` is logged once and the first entry is kept.

All text from the sidecar is escaped, so it shows as written.

## The `at` rule

Set `at` to the percentage at the **end of the chapter** in which a fact is revealed, not where it first appears. The fact then shows when you finish that chapter. This absorbs small differences between an AI's word count and Kobalt's, and Kobalt's estimate of the position inside a chapter. The builder in [`authoring/tools`](authoring/tools/make_sidecar.py) computes `at` from chapter numbers, so a source written by chapter needs no percentages.

Knowledge from earlier books in a series goes in at `at: 0`. Every character needs a summary at the point where it is introduced.

## Validate a sidecar

Any JSON Schema validator that supports draft 2020-12 can check a sidecar against [`sidecar.schema.json`](sidecar.schema.json). For example, with `check-jsonschema`:

```sh
check-jsonschema --schemafile xray/sidecar.schema.json "Wolf Hall.xray.json"
```

## Writing a sidecar

[`authoring/`](authoring/README.md) holds what you need to write a sidecar for a whole book: a way of writing it by chapter and letting a tool compute the percentages from your EPUB, prompts for the models that can help, a checking script, and measurements of what each way of working costs. Start with [`authoring/README.md`](authoring/README.md). If you only have a chat app, [`authoring/prompts/one-shot.md`](authoring/prompts/one-shot.md) has the prompt that used to be in this section, improved, and says plainly that it is untested.

## Tests

`tests/xray_test.lua` covers this plugin. See [Tests](../README.md#tests) in the root README to run it.
