# Demos

This folder holds small plugins that each show part of the plugin API. They are examples to read and copy, not finished features. To try one, copy its folder into the plugin folder of your platform under the same name, for example `demo/hello/` to `.adds/kobalt/plugins/hello/` on Kobo. Kobalt requires the folder name to match the plugin's `id`. Each demo adds an entry to the dictionary chooser when it has an answer; Settings > System > Plugins shows whether it is running and turns it off.

| Demo | Shows | API |
| --- | --- | --- |
| `hello` | A card that repeats the word you looked up. Start here. | `before_lookup`, escaping card HTML |
| `glossary` | Definitions of typography terms, from `glossary.json` in its folder. | `book_opened`, `book_closed`, `kobalt.read_file`, `kobalt.json.decode`, `kobalt.log` |
| `position` | The book title, chapter, page and percentage that Kobalt passes with each lookup. | the `ctx` table |
| `history` | How often you have looked up a word, in this book and in all books. | `require`, `kobalt.store`, `kobalt.book_store` |

## Lookup history

Shows how many times you have looked up a word in this book, the page of the first lookup, and how many times in all books. Words count the same in any letter case.

The plugin splits its code into modules in `history/`, loaded with `require("history.record")` and `require("history.card")`. It keeps counts in `kobalt.store`, shared by all books, and `kobalt.book_store`, kept for each book. Kobalt saves that data outside the plugin folder, so replacing the folder for an upgrade keeps the counts:

| Platform | Plugin data folder |
| --- | --- |
| Kobo | `.adds/kobalt/plugin-data/history/` on user storage |
| Android | `plugin-data/history/` in the app's external files folder |
| Desktop | `plugin-data/history/` in the Kobalt profile folder |

Delete saved data in the plugin's Settings details removes the counts.
