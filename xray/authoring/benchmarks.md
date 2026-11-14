# What I measured

These are the measurements behind the routes in [Writing sidecars](README.md#choosing-a-route). They are few, from one person's runs on a handful of novels, and should be read that way. Nothing here was measured for any route that is not listed.

## Setup

- Local models ran under [Ollama](https://ollama.com) on one 24 GB GPU, with a context of 16,384 tokens, output constrained by a JSON schema, and thinking mode off. Two of the longer books needed a context of 24,576 for their longest chapters. An answer cut off at the output limit is asked again warmer and with twice the room.
- Claude models ran as sub-agents of Claude Code.
- *Agent tokens* are the total that the harness reports for a sub-agent: input, including cached re-reads, plus output. They compare runs with each other. They are not a bill.
- *Share of a window* is the share used of the 5-hour usage window of the Claude Max plan at about $100 a month. On another plan the share differs.
- Times are wall-clock minutes for the run.

## Chapter notes

The first benchmark is only the first step: how well each model logs a chapter with the prompt in [prompts/chapter-notes.md](prompts/chapter-notes.md). One call per chapter, on five chapters of Count Zero: chapters 1, 14, 16 and 28, and chapter 1 of a Spanish translation of the novel.

The method of scoring is by keyword. The answer key, 54 named people and 26 key facts, was made by reading the five chapters. A person or fact counts as found when the model's notes for those chapters contain it.

Local models, time per chapter:

| Model | People of 54 | Facts of 26 | Seconds per chapter | Remarks |
| --- | --- | --- | --- | --- |
| `qwen3.8:27b` | 49 | 23 | 34 | The best of the local models. Clean lists |
| `gemma4:31b` | 50 | 20 | 73 | Caught a reveal that qwen missed. One factual slip |
| `bonsai-2:27b` | 50 | 19 | 59 | Lists organisations as people, and far too many terms |
| `gemma4:26b` | 44 | 19 | 11 | Very fast, weaker recall, few relationships |
| `mistral-small3.2` | 49 | 17 | 72 | Weakest on facts, noisy |

Claude models, one sub-agent per model for the five chapters together, with no who-is-who list:

| Model | People of 54 | Facts of 26 | Seconds, all five chapters | Agent tokens |
| --- | --- | --- | --- | --- |
| Fable 5.2 | 54 | 25 | 188 | 128k |
| Opus 5.5 | 53 | 24 | 154 | 124k |
| Sonnet 5.5 | 51 | 23 | 104 | 123k |

What I found besides the scores:

- No local model wrote Spanish for a Spanish chapter when told to write "in the language of the chapter". With the language named outright, qwen and gemma did, and used the translation's own terms.
- Every local model misread the end of chapter 28: it took a caller on the phone for another character. A short who-is-who list of the earlier chapters fixed it for `qwen3.8:27b`. All three Claude models read it correctly without help.
- The keyword score understates that. The local models' weakness is who did what, not coverage.
- Thinking mode overran the output budget and broke the JSON, so it is off.

## Whole book: Count Zero

Count Zero has 86,500 words and 36 chapters. Each result is scored against a reviewed source of 247 entries: 50 people, 197 terms and 250 relationships. The reviewed sources, which are in [glaucon1984/kobalt-xray-sidecars](https://github.com/glaucon1984/kobalt-xray-sidecars), were made with four reader agents and one writer agent on Claude Fable 5.2 and then reviewed for spoiler timing. That took 510k to 620k agent tokens for the readers, plus 355k to 490k for the writer: about 0.9 to 1.1 million agent tokens and 30 to 35 minutes a book.

"People found" is the number of the reviewed file's 50 people that the result has. "Same chapter" is the number of those introduced in the same chapter as in the reviewed file. "Terms shared" is the number of the reviewed file's 197 terms that the result also has. A dash means I did not record it.

| Route | Entries | People found | Same chapter | Terms shared | Relationships | Agent tokens | Minutes | Share of a window |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Reviewed source (Fable 5.2 readers and writer, then reviewed) | 247 | 50 | - | 197 | 250 | 0.9 to 1.1 million | 30 to 35 | - |
| Local model alone (`xraygen`, `qwen3.8:27b`) | 157 | 47 | 41 | 52 | - | none | about 23 | none |
| Local notes, Sonnet 5.5 writer, first brief | 162 | 48 | 47 | 87 | 141 | 447k | 17 | 6 % |
| Local notes, Opus 5.5 writer, first brief | 164 | 48 | 45 | 90 | 190 | 438k | 18 | 27 % |
| Local notes, Sonnet 5.5 writer, the brief in [prompts/writer.md](prompts/writer.md) | 250 | 49 | 46 | 128 | 240 | 607k | 22 | 6 % |
| Agents only, no GPU: four Sonnet 5.5 readers, Sonnet 5.5 writer, the same brief | 226 | 48 | 43 | 130 | 163 | 1.17 million (550k readers, 620k writer) | 30 (readers 4, side by side; writer 26) | - |

The "local notes" rows used the notes of `qwen3.8:27b`, which cost no paid tokens. The agent tokens, minutes and share of a window in those rows are for the writer. The "agents only" row was run once, alongside other work, so its share of a window was not isolated; its readers each took 20,000 to 25,000 words and none of them saw the other readers' chapters.

What the comparison shows:

- The local model alone has the people, with some wrong statements about who did what, and turning points fade from its later cards.
- Both writers corrected the local notes' mistakes about who did what by checking the book.
- The brief mattered more than the model. The same model, Sonnet 5.5, went from 162 to 250 entries with the new brief, which asks for coverage, for a candidate list of terms taken from the book's own text, and for self-checks.
- Opus 5.5 gave the same result as Sonnet 5.5 and used 4.5 times as much of the window (27 % against 6 %).
- Without a GPU, reader agents on Sonnet 5.5 gave the writer notes that led to about the same accuracy as the local notes did (48 of 50 people, 130 of 197 terms), for about twice the agent tokens. That file is a little smaller, 226 entries and 163 relationships against 250 and 240, from one run of each: I cannot say how much of that is the notes and how much is chance.
- Agreement on terms is 128 of the reviewed file's 197. The file has about the same size, but it is not the same choice of terms.

## Longer books

Seven longer books, made with the notes of `qwen3.8:27b` (with the language named) and a Sonnet 5.5 writer: Spanish translations of Liu Cixin's trilogy and of Richard Morgan's Kovacs trilogy, and one novel in English, Christopher Ruocchio's *Empire of Silence*. There is no reviewed file for any of them. The builds are clean, and a sample of cards was read against the book.

| Book | Words | Chapters | Local step | Entries | Summaries | Relationships | Writer, first version | Passes after it |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| *El problema de los tres cuerpos* | 122,000 | 35, numbered | 16 min | 262 | - | 173 | 748k agent tokens and 34 minutes, including one correction pass | one, included |
| *El bosque oscuro* | 195,000 | 45 parts, from unnumbered sections cut with `--chapter-split 4500` | 25 min | 321 | 724 | 246 | 900k agent tokens, 42 minutes, 13 % of a window | two, of 7 and 9 minutes |
| *El fin de la muerte* | 243,500 | 91 parts | 33 min | 392 | 792 | 306 | 683k agent tokens, 35 minutes, 10 % of a window | one, of 7 minutes |
| *Carbono modificado* | 161,000 | 44, titled in words | 31 min | 283 | - | 247 (133 in the first version) | 528k agent tokens, 24 minutes | one, of 4 minutes |
| *Ángeles rotos* | 154,000 | 43, titled in words | 37 min, stopped once | 267 | - | 252 (174) | 660k agent tokens, 25 minutes | one, of 3 minutes |
| *Furias desatadas* | 189,000 | 51, titled in words | 48 min, stopped once | 339 | - | 411 (135) | 777k agent tokens, 40 minutes | one, of 7 minutes |
| *Empire of Silence* | 240,000 | 78, labelled "Chapter 12: Title" | about 40 min, stopped once | 385 | 678 | 240 | 653k agent tokens, 30 minutes | one, of 2 minutes |

- The three Kovacs writers and the checking of their work together took 26 % of one window. The *Empire of Silence* writer, its pass and the review took 8 %.
- Each Kovacs writer had the finished sources of the earlier books as its examples, and no chapter was split.
- The local step stopped once in three of these books, on an answer that ran into the output limit. The two Kovacs runs went on with 12,000 tokens of output and a context of 24,576. The *Empire of Silence* run went on after `xraygen` learned to ask a cut-off answer again warmer; see [prompts/chapter-notes.md](prompts/chapter-notes.md#notes-on-using-it).
- All three Kovacs first versions had about half as many relationship items as entries. A correction list that named the characters without ties fixed it.
- Every one of the Kovacs books' secrets was staged correctly in the first version: a body worn by someone else, a saboteur, a younger copy of the main character, and a personality that claims to be a historical figure.

## Faults found in review

Each of these is now a rule in the brief or a check in [prompts/review.md](prompts/review.md). They are listed as found, before those rules.

- 67 of the 262 entries of one book began at the end of a chapter, so they could not be looked up in their first chapter.
- Names answered ordinary words: "Pan Han" answered every "han", 65 times, and "Leonardo da Vinci" every "da".
- Later summaries were written as change notes in 48 entries of one book ("recently revived, ..." without saying who the person is).
- Relationships went stale in every long book: a present tense about a passing event was still on the card at the end of the book.
- Three cards were wrong about the ending of one book. The writer had read about a sixth of the text in full, and not the last chapters.
- Entries meant to be "known before the book" held facts that the book itself tells first.
- Cards stopped being updated two thirds into a long book.
- The wording of relationships had slips in every run: ties left stale after a death, and ties whose subject switched in the middle of the sentence.
- Three first versions had about half as many relationship items as entries, so many characters had no ties at all.
- One card commented on the book ("the book does not confirm that ..."), after stating as fact what the book gives only as one character's accusation.
- In a book told in the first person, the narrator's closing words to the reader became a fact in the main character's last summary.
- One fault was mine as the reviewer: I sent a correction that the book proves wrong, after a search that missed the sentence. The writer quoted the passage and rightly kept its card.

## Limits

- The sidecars made with local notes and a writer had not yet been tried on a device when this was written. The reviewed ones had.
- Only one book, Count Zero, has a reviewed file to score against.
- A writer reads only part of a long book in full: about half of 195,000 words, about a sixth of 243,500, about 12 % of 240,000. The faults that remain are in the places it did not read.
- Each of the seven longer books needed at least one correction pass.
- Hosted models other than Claude were not measured, and neither was the cost in money of a hosted API.
- The route with an OpenAI-compatible API was tested for the protocol only, against a local endpoint.
