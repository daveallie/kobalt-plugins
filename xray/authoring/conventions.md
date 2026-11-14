# Conventions for the source file

These are the rules for the source file that [`tools/make_sidecar.py`](tools/make_sidecar.py) turns into a sidecar. Some come from how the plugin matches names, which the [plugin README](../README.md) describes, and some come from faults I found in review. [benchmarks.md](benchmarks.md#faults-found-in-review) says how often.

## Format

A source is JSON in UTF-8, with no `null` anywhere. Its top level has `book`, `notes` and `entries`, and optionally `chapter_pattern` and `chapter_split` (see [Books with unnumbered or very long chapters](README.md#books-with-unnumbered-or-very-long-chapters)). The docstring at the top of `make_sidecar.py` defines the format. Use `notes` to say how the source was made, for instance that a model wrote it from chapter notes and a person has not reviewed it.

Each entry has:

- `id`: unique, lower case.
- `name`: what the card is titled with.
- `aliases`: optional. A string, or an object `{ "text": "...", "when": "e20" }` that matches only from that point on.
- `summary`: a list with at least one item, each `{ "when": ..., "text": "..." }`.
- `relationships`: optional, each `{ "when": ..., "with": "<other id>", "text": "short phrase" }`. `with` must be an existing id.
- `seen`: optional, a list of chapter numbers where the entry appears in person, not merely mentioned. Each becomes a "last seen" line that shows once that chapter is finished. Use it for main and secondary characters only.

Texts are short, plain and free of markup. Write them in the language and spelling of the book, and in your own words: do not copy sentences from the novel or from a glossary.

## When a fact shows

`when` is one of:

- `0`: from the start of the book. Use it for world vocabulary that gives nothing of the plot away and, in a later book of a series, for what the earlier books told. Nothing in a `0` text may be something this book tells for the first time.
- `"sN"`: from the first page of chapter N.
- `"eN"`: from the last page of chapter N. The builder places it a little before the chapter's computed end, about half a page of a novel, so that a small difference from Kobalt's own word count cannot push it into the next chapter.
- A number: a percentage of the book, as it is. This is the only form the plugin itself knows, and it is rarely what you want in a source.

Never reveal anything before the chapter whose text states it. Where the chapter notes say a thing is only hinted, do not state it as fact at that point.

## Introductions at the start, reveals at the end

Put the introduction of a person or term at `sN`, where N is the chapter in which the name first occurs, and say there only what the first pages of that chapter show: who or what it is at first sight. Put everything the chapter reveals at `eN`. For example, a character's first summary can say a woman in black with mirrored lenses; the summary at the end of that chapter says what she does and for whom.

This departs from [the `at` rule](../README.md#the-at-rule) of the plugin README, which sets `at` to the end of the chapter that introduces someone. The reason is that a reader can press a name as soon as it appears. With the introduction at the chapter's end, a character cannot be looked up in the chapter that introduces them. Reveals stay at the end of their chapter, as the rule says, so nothing shows before the chapter has been read.

Therefore no entry may begin with an `eN` summary. If its first summary is `eN`, the entry cannot be looked up in the chapter that introduces it. [`tools/check_source.py`](tools/check_source.py) lists such entries. A term whose meaning is itself a revelation is staged: first what the reader can know, then the truth at the chapter that reveals it. One of my examples gives a name first as a single word handed to a character as a message, with nothing said about what it means, and only later says that it is the code name of an artificial intelligence.

## Summaries that stand alone

A later summary is the whole picture at that point, in one or two sentences, and it replaces the earlier one. It is never a change note such as "Now he is dead". The card shows only the latest summary in force, so every summary, the first and every later one, opens with who or what the entry is, in a stable clause that gives nothing away, such as profession and role, and then gives the state at that point. A reader who presses a name at that point must learn who the person is.

A summary that only reports the latest change is wrong, and so is one that opens with "recently revived" or "after the battle" without saying who the person is. In one book I found this in 48 entries. A good chain repeats the identity clause. In one of my finished sources, the later summaries of a main character open with the same clause, "Console cowboy from the Sprawl, repaired in Chiba and held to Armitage's job by toxin sacs in his arteries.", and then give the news of that chapter.

For a main character, write a summary at each chapter that changes their picture. Give the last third of the book the same care as the first: in one long book the cards stopped being updated two thirds of the way in.

## Relationships

On A's card a relationship with B reads "B: text", using B's `name`. So the text describes what B is to A, and it must be worded from that side. A relationship stays hidden until the other entry is known.

An item stays on the card until a later item to the same entry replaces it, perhaps hundreds of pages on. So:

- A later item replaces the earlier one and must still state the whole relationship as known at that point, not something weaker or odder.
- Word a tie so that it stays true: "boss who hired her", not "boss who hires her today". A tie that is true of a moment goes stale.
- Add a later item at the chapter where the tie changes or ends.
- Do not make a relationship out of a single incident.
- Give a main character a relationship with every other entry that matters to them: people, organisations and places they are tied to. Give every character with a `seen` list the two or three that define them.

Check each chain as it stands at the end of the book. Stale items and slips in wording turned up in every run.

## Secrets

`name` and plain string aliases are visible as soon as the entry is known, and `name` shows on other entries' relationship lines. So they must never give a secret away. When the book later reveals that two names are one person, do as the plugin README says: keep a separate entry for the stranger until the reveal and link them then, or give the person an alias object with the reveal's `when`. In one finished source, a colonel's real name and rank are aliases that start at the chapter that reveals them. Check that no `seen` chapter, relationship or alias gives away a reveal either.

## Simulations and stories within the story

A figure inside a simulation, a game, a construct, a recording or a story told within the book is not a person of the main story. Say which it is. Keep a person and the name they use there apart until the text links them, and never write that something happened to the person when it happened to their image. In one finished source, a famous dead cowboy has one entry whose first summary says only that, and whose later summaries say that what the team carries is a recording of him, which answers as he would but keeps no memory.

## How matching works

The plugin compares the pressed word, ignoring case, punctuation at either end and a trailing `'s`, with the full `name`, every single word of `name`, and each alias as a whole. An alias that begins with "the " also matches without it. A long press usually selects one word, so list single-word aliases: first name, surname, nickname, title, plural and other inflected forms.

Two entries may share a word, such as two people called Roberts. They stack in one card, which is fine. The builder prints a `note:` line for each.

The traps:

- Common words in a name. Every word of `name` is indexed. "New Yen" would answer every "new", and in one Spanish translation "Pan Han" answered every "han", 65 times, and "Leonardo da Vinci" every "da". Name the entry "Yen" and add the alias "New Yen".
- "The X" aliases. An alias such as "the Place" or "the well" would answer every "place" or "well". Never write one.
- Display names that need a common word. When the name must read "People of Importance", "Lord of Roads", "Street samurai" or "Black medicine", write it with no-break spaces, as ` ` in the JSON: `"Street samurai"`. The plugin splits a name at ordinary white space only, so this is one key that never matches, and it looks the same on the card. Add the normal spelling as an alias, and any single word that is safe ("samurai"). The builder does not check no-break names for occurrence in the book, since they are for display only; their aliases are checked.
- Ordinary words that are also names. Because matching ignores case, a name such as "Deck" or "ICE" answers the ordinary word too. That is acceptable for a real glossary term, which the reader may well want explained, and the dictionary still opens first. Avoid it for very common words. For every word of every name and every single-word alias, count its lower-case occurrences in the book. A high count means an ordinary word. Keep a single-word alias only where the word nearly always means the entry in this book; otherwise give the name the no-break form or drop the alias.

`check_source.py` prints these counts. The builder itself only catches a name word that is a stop word such as "the" or "of".

## Scope and density

People: every named character who matters at all, including minor named ones (one short summary is enough), every named real or historical person the text mentions, with a line on who they were that helps a reader of this book, and every named non-human entity such as an AI, a construct or a spirit. Skip unnamed people. An unnamed person known only by a job is skipped; an organisation is a term, not a person.

Terms: invented jargon, technology, slang, corporations and brands, drugs and weapons, places of the setting, vocabulary of the period, and real-world references a reader may want explained. Only terms that occur in the book's text. Each gets a short, correct explanation placed at the chapter where it first occurs, or at `0` when it is general knowledge that gives nothing of the plot away.

Density follows from covering the book: every named person and every term a reader might press and want explained. Never reach a number with ordinary words or with entries nobody would press. What I found:

- Up to about 120,000 words, 2 to 3 entries for every 1,000 words. Count Zero has 247 entries for 86,500 words, and a Spanish translation of 122,000 words has 262.
- For a longer book, about 1.5 to 2 for every 1,000 words, because the cast and the vocabulary grow more slowly than the text. Books of 154,000 to 189,000 words came to between 267 and 339, and books of 195,000, 240,000 and 243,500 words to 321, 385 and 392.
- A large cast and much invented vocabulary sit at the high end.

## Checking the builder's notes

Run the builder after every change. It prints:

- An `error:` line: fix it.
- `"..." does not occur in the book`: fix the spelling, or drop the alias or the entry. A name written with no-break spaces is exempt.
- `"..." first occurs in chapter X, before the entry is known (chapter Y)`: check it. If the person or term really is first met in chapter X, move the introduction to `sX`. If it is another use of the same word, such as a common word or another person's name, leave it.
- `would answer every ...`: fix the name as described above.
- `note: ... answers for a, b`: informational.

Then run [`tools/check_source.py`](tools/check_source.py) for what the builder does not check, and read as [prompts/review.md](prompts/review.md) describes.
