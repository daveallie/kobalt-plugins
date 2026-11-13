# Brief for the writer

This is the brief for step 3 of [Writing sidecars](../README.md#the-steps). The writer is one agent, such as a sub-agent of a coding agent, that reads the chapter notes and the book, writes the source file, builds it, and works through the builder's notes. Send it the brief below, with the parts in angle brackets filled in.

The writer needs a computer on which it can run Python and read files. It works alone, and it must not start sub-agents of its own.

## Which model

I used Claude Sonnet 5.5 at high effort. On Count Zero, Claude Opus 5.5 scored the same as Sonnet 5.5 with the first version of this brief and used 4.5 times as much of the 5-hour usage window, so Sonnet is the model to start with. See [benchmarks.md](../benchmarks.md#whole-book-count-zero). A hosted model other than Claude was not measured.

## Filling it in

- `<repo>`: a clone of this repository.
- `<work>`: your work folder, with the EPUB in it as `book.epub`.
- `<notes>`: the folder that holds the `chapter-*.json` files of [step 2](chapter-notes.md). With `xraygen` it is `<work>/work-<hash>/`.
- `<notes writer>`: who wrote the notes, such as "a local model" or "reader agents".
- `<title>`, `<author>`, `<language>`, `<book-slug>`: the book's title and author, the language the cards are written in, named outright (such as "English" or "Spanish"), and a short file-name form of the title.
- `<example>`: a finished source, for instance one from [github.com/glaucon1984/kobalt-xray-sidecars](https://github.com/glaucon1984/kobalt-xray-sidecars), downloaded to your computer. For a later book of a series, the source of the previous book; for a third book, the sources of both earlier books. Otherwise one in the same language if there is one.
- `<chapter options>`: the options you chose in step 1, such as `--chapter-pattern '...'` or `--chapter-split 4500`, or nothing.
- `<source options>`: when there are chapter options, this sentence, leaving out the key that was not used. Otherwise nothing.

  > The source must carry the same choices at its top level, beside "book": "chapter_pattern": "<the pattern>" and "chapter_split": <the number>; then the build needs no options. A part such as "Title (3/15)" is a chapter like any other.

- `<series note>`: for a later book of a series, the first sentence below. Otherwise, the second.

  > This book follows <earlier book>. What the earlier books established may go in at "when": 0, reworded, when it occurs in this book; never attach it to a character who appears here under another name until this book's text makes the link.

  > It is a different book, and may be in another language: take the structure, the staging and the tone from it and nothing else.

- `<target>`: for a novel of up to about 120,000 words, 2 to 3 entries for every 1,000 words, given as a range; for a longer one, about 1.5 to 2 for every 1,000 words, because the cast and the vocabulary grow more slowly than the text. Count Zero came to 250 entries for 86,500 words, a 122,000-word novel to 262, and books of 195,000, 240,000 and 243,500 words to 321, 385 and 392. A large cast and much invented vocabulary sit at the high end.
- `<outside the chapters>`: when the EPUB has a cast list, a timeline, a glossary, a lexicon or an index of places outside the chapters, this sentence. Otherwise nothing.

  > The EPUB contains <what> outside the chapters: they are not evidence for anything and give the book away, so take nothing from them.

- `<narration note>`: optional, for a book told in the first person by a narrator who looks back. I used the sentence below on one such book. The foreshadowing came out right, but the narrator's closing words to the reader still became a fact on a card, which is why the sentence now names them; how much of the result the note explains is untested. Otherwise nothing.

  > A note on this book: it is narrated in the first person by an older <name> looking back, and the narrator often foreshadows what is to come ("I did not know then that..."). Such a hint, or the narrator's words to the reader, tells the reader something only in the vague form it is given; do not turn it into a fact on a card before the chapter where the story itself reaches it.

- `<kinds of terms>`: what this book is full of, in a few words, for example "invented jargon, corporations and brands, drugs and weapons, places" or "physics and astronomy, the vocabulary of the period and its politics, historical figures, places".

On Windows, set `PYTHONIOENCODING=utf-8` before the Python commands, as in the examples of the README.

## The brief

```text
You are the writer in a two-stage pipeline that makes "X-Ray" sidecars for the Kobalt e-reader: a card shown when the reader long-presses a name or term, limited to what they have read so far. Stage 1 is done: <notes writer> read <title> by <author> chapter by chapter and wrote a log per chapter. Your job is stage 2: write the complete source file from those logs and from the book, build it, and work through the builder's notes until only harmless ones remain. Work alone: do not start sub-agents.

Write every card in <language>, and use the book's own names and terms exactly as this edition spells them. The reader presses a word in this text, so names and aliases must be forms that occur in it.

Read, in this order:
1. <repo>/xray/authoring/conventions.md - the conventions and the plugin's matching rules. Follow it. Its examples of unsafe names are English; the same rules apply in any language.
2. <repo>/xray/authoring/tools/make_sidecar.py - only its docstring, which defines the source format.
3. <example> - a finished, reviewed source. <series note>
4. The chapter logs: <notes>/chapter-*.json. Read all of them in full. In that folder read only the files whose names start with "chapter-".
5. The book: <work>/book.epub. An EPUB is a zip of XHTML files; write a small Python script in your output folder that prints a chapter, searches the book with a regular expression, and reports the first chapter and the count of a word. Take the chapters from the builder's own code, since a chapter may be a part of a file: with <repo>/xray/authoring/tools on sys.path, `from make_sidecar import Book; Book(path).chapter_texts(pattern, split)` gives each chapter's number, label and paragraphs (the default pattern is r"^(\d+)\b" and the default split None; use the ones of the chapter list below). Use it whenever the logs are unclear, contradict each other or look wrong, and for the coverage pass below.

Do not read any existing source or sidecar for this book (the work folder may hold a draft that a generator made, such as draft.source.json), the "card-", "sift-" and "same-" files beside the logs, the source of a later book in the same series, or the web. <outside the chapters> <narration note> Your memory of the book is not evidence for where a fact belongs: place every fact by the chapter whose log or text states it, and check in the EPUB when unsure.

What the logs get wrong. They are good on who appears and roughly what happens, and weaker on detail. Expect:
- wrong attributions inside "learned": one person credited with another's action. Where a statement matters to a card and looks doubtful, check the chapter text;
- names given wrongly or inconsistently. The book's spelling decides;
- a person who appears unnamed in a chapter is not tied to their name. Tie them yourself when the text supports it, but do not list that chapter in "seen" if the reader cannot yet know it was them;
- organisations and job titles listed as people. Organisations are terms; an unnamed person known only by a job is skipped;
- ordinary words listed as terms, and real terms missing;
- "same_as" links that are wrong or missing. An identity the book keeps secret must be handled as the conventions say, with separate entries or timed alias objects until the chapter that reveals it.

Coverage. For this book expect roughly <target> entries. That number is what covering the book produces; never reach it with ordinary words or with entries nobody would press.
- People: every named character, however minor (one short summary is enough for a minor one), every named real or historical person the text mentions, with a line on who they were that helps a reader of this book, and every named non-human entity.
- Terms: do not rely on the logs for these. Write a script that lists candidates from the book's own text: capitalised words and capitalised multi-word names that are not at the start of a sentence, words set in italics in the XHTML, acronyms, hyphenated coinages, and words with unusual frequency, each with its count and first chapter. Go through that list for <kinds of terms>, and for works, songs and foreign words that are named. Each term gets a short, correct explanation, placed at the chapter where it first occurs, or at "when": 0 when it is general knowledge that gives nothing of the plot away. A term whose meaning is itself a revelation is staged: first what the reader can know, then the truth at the chapter that reveals it.
- Relationships: a main character needs a relationship with every other entry that matters to them (people, organisations, places they are tied to), each updated with a later item at the chapter where it changes. A later item to the same entry replaces the earlier one, so it must still state the whole relationship as known at that point. On A's card the relationship with B reads as "B: <text>", so the text must describe what B is to A. An item stays on the card until a later one to the same entry replaces it, perhaps hundreds of pages on: word a tie so that it stays true ("boss who hired her", not "boss who hires her today"), add a later item at the chapter where it changes or ends, and do not make a relationship out of a single incident. Every character with a "seen" list needs the two or three that define them. A finished file has at least six relationship items for every ten entries, and often about one for each; a file with half as many relationships as entries has left characters without ties.
- Summaries: a main character needs a summary at each chapter that changes their picture, each one the whole picture at that point in one or two sentences, and a "seen" list.

Checks to run on your own file before you report:
1. Introductions. Every entry not at "when": 0 must begin with an "sN" summary for the chapter where its name first occurs: one sentence saying only what the reader sees at first sight, with nothing the chapter reveals later. Everything the chapter reveals goes in an "eN" summary after it. No entry may begin with "eN": such an entry cannot be looked up in the chapter that introduces it.
2. Ordinary words. Every word of "name" is indexed and matching ignores case. For every word of every name and every single-word alias, count its lower-case occurrences in the book. Where it is an ordinary word that mostly means something else, give the name its no-break-space form with the normal spelling as an alias, or remove the alias. Keep a single-word alias only where the word nearly always means the entry in this book.
3. "seen" lists. Check each main character's "seen" chapters against the text with a case-insensitive search, and that no "seen" chapter gives away a reveal.
4. Simulations and stories. A figure inside a simulation, a game, a construct, a recording or a story told within the book is not a person of the main story: say which it is, keep a person and the name they use there apart until the text links them, and never write that something happened to the person when it happened to their image.
5. Summaries that stand alone. The card shows only the latest summary in force, so every summary, including every later one, must open with who or what the entry is (a stable identity clause that gives nothing away, such as profession and role) and then give the state at that point. A summary that only reports the latest change is wrong: a reader who presses the name at that point would not learn who the person is. Print every non-first summary of every entry that has more than one, read them one by one, and rewrite those that do not stand alone.
6. The end of the book. Print, for every entry with relationships, each chain as it stands at the end (the last item per "with"), and the last summary of every entry with four or more: each must still be true and complete on the last page. Read the last chapters in full for this; the cards of the ending are where the logs are thinnest.
7. Before the book. Print every "when": 0 text: it may hold general knowledge and what earlier books told, and nothing that this book states for the first time.
8. Reread the file as a reader would at a third, at two thirds and at the end of the book. For the main characters and for the terms that carry the book's secrets, check that no card says anything the reader cannot know yet and that each card is right about who did what.

Produce:
- Your output folder is <work>/writer/. Write the source there as <book-slug>.source.json. Write nothing outside that folder, change nothing in the repository and run no git commands.
- List the chapters first, from the repository root <repo>:
  python xray/authoring/tools/make_sidecar.py <work>/book.epub --chapters <chapter options>
  The numbers in that list are the chapter numbers of the logs (chapter-NNN) and of your "sN", "eN" and "seen". <source options>
- In "notes", say that the source was written by a model from <notes writer>'s chapter logs and has not been reviewed by a person.
- Build with:
  python xray/authoring/tools/make_sidecar.py <work>/book.epub <work>/writer/<book-slug>.source.json -n <book-slug>
  Fix every error and deal with each note as the "Checking the builder's notes" section of the conventions says, rebuilding until what remains is harmless.
- Give the last third of the book the same care as the first. If you build the source with a generator script, keep that script in the output folder.

No card may comment on the book itself ("the book does not confirm...", "the text does not say..."): a card states what the reader knows at that point, in the story's terms. What the book gives only as one character's accusation or theory is stated as theirs, not as fact.

Report, briefly and as plain text: the number of entries, how many are people and how many terms, and how many of the terms came from your own pass over the book; the builder's remaining notes and why each kind is harmless; the result of each of the eight checks; where you overrode the logs after checking the book; how you handled the book's secrets; how much of the book you read in full; what you are unsure about.
```

## After the writer reports

Its report is not proof. Go on to [review.md](review.md).
