# Reviewing the writer's work

This is what you check after the writer reports, in step 4 of [Writing sidecars](../README.md#the-steps), and how to send the faults back in step 5. The writer's report is not proof, because its own checks do not catch everything. You can do this yourself, or ask your coding agent to do it in its main session.

## The helper

[`tools/check_source.py`](../tools/check_source.py) prints what the first four checks below need. It builds the source in memory with `make_sidecar.py` beside it and writes nothing.

```sh
python xray/authoring/tools/check_source.py <work>/book.epub <work>/writer/<book-slug>.source.json --cards <id>,<id> --at 33,66,100
```

It prints:

- the counts of entries, summaries and relationships;
- the builder's notes by kind, with every `error`, "does not occur", "would answer" and "first occurs" line;
- the entries that begin at the end of a chapter;
- the lower-case counts of name words and single-word aliases: every word that occurs in lower case `--words` times or more (default 5), with its count in all cases beside it;
- the later summaries that open like a change note;
- with `--cards`, each named card as a reader sees it at each percentage of `--at`: the summary in force, the relationships in force, and where the character was last seen.

Its list of change-note words is English and Spanish. Add the words of your language to `CHANGE` at the top of the script.

## The checks

1. Rebuild, with the command in the brief. There must be no `error:` line and no "does not occur" line. Each "first occurs ... before the entry is known" line must be another use of the same word, such as a common word or another person's name; if it is the same person or term, the introduction is in the wrong chapter.
2. No entry may begin with an `eN` summary. An entry that does cannot be looked up in the chapter that introduces it.
3. For every word of every name that has no no-break spaces, and every single-word alias, look at the lower-case counts. A high count means an ordinary word that will open the card everywhere. Names get the no-break-space form, and plain-word aliases go, unless the word nearly always means the entry in this book.
4. Every later summary must stand alone. The card shows only the latest summary, so one that reports a change without saying who the person is leaves the reader with no answer. The script catches only the ones that open with a word such as "now" or "after". Read the later summaries of the main characters yourself.
5. Read the cards of the four or five main characters, and of the terms that carry the book's secrets, as they stand at a third, at two thirds and at the end. Look for a fact shown before its chapter, a secret given away by a name, a plain alias, a relationship or a `seen` chapter, and mistakes about who did what. Check doubtful statements in the EPUB with a case-insensitive search: a transcript or a heading may print names in capitals.
6. Relationships are where slips remain: one worded from the wrong side, a later item that replaces a stronger earlier one with something weaker or odd, and above all items that go stale, such as "organisation where she works" still on the card centuries of story later. Run the script with `--at 100` on the main characters and read every chain as it stands at the end.
7. Read the ending against the book. A writer reads only part of a long book in full, so the last chapters are where the cards are thinnest. Read the last chapters yourself and compare.
8. Read the `when: 0` texts. In a later book of a series they drift into what this book tells in its first chapters. In any book, an entry meant to be "known before the book" must not hold a fact that the book itself tells first.
9. Look at the last third of a long book: the cards of the main characters must still be updated there.

## The faults I found

Each of these became a rule in the brief or a check, so it is rarer now. [benchmarks.md](../benchmarks.md#faults-found-in-review) lists them with the books.

| Fault | How often | Check |
| --- | --- | --- |
| Entries that begin at the end of a chapter, so that they cannot be looked up in their first chapter | 67 of 262 entries in one book, at first pass | 2 |
| Names that answer ordinary words ("Pan Han" answered every "han", 65 times; "Leonardo da Vinci" every "da") | Several names in the same book | 3 |
| Later summaries written as change notes, without saying who the person is | 48 entries in one book | 4 |
| Relationships that go stale: present tense about a passing event, still on the card at the end of the book | Every long book | 6 |
| Cards wrong about the ending of the book | 3 cards in one book, where the writer had read about a sixth of the text in full and not the last chapters | 7 |
| "Known before the book" entries that held facts the book tells first | Found in review | 8 |
| Cards that stopped being updated two thirds into a long book | Found in review | 9 |
| Slips in the wording of relationships | Every run | 6 |

After the brief gained the checks for the first two faults, the next run had no entry that began at the end of a chapter, and only a few aliases that were ordinary words.

## Sending the faults back

Send the faults to the same writer, which keeps its context, as one numbered list. A correction pass took 4 to 9 minutes. Then read the result again: a pass fixes what was listed and little else, so check that the listed faults are gone, that nothing else changed that should not have, and that the build is still clean. Fix a single wording slip yourself, in the source and in the writer's generator script if it made one, and rebuild.

A template:

```text
I rebuilt and read your source. Fix the faults below in the source (and in your generator script, if you used one), rebuild, and then report what you changed. Fix what is listed. If you find the same fault in other entries, fix those too and say which.

1. <id> begins at "e<N>". Add an "s<N>" summary for the chapter where its name first occurs, saying only what the reader sees at first sight, and keep the "e<N>" summary after it.
2. <id>: the name word "<word>" occurs <n> times in lower case in the book. Give the name its no-break-space form and keep the normal spelling as an alias.
3. <id>, summary at <when>: it does not say who the person is. Open it with who or what the entry is, then give the state at that point.
4. <id>, relationship with <other id>, at <when>: "<text>" is worded from the wrong side. On <id>'s card it must say what <other id> is to <id>.
5. <id>, relationship with <other id>: "<text>" is still on the card at the end of the book and is no longer true. Add a later item at chapter <N>, where it ends.
6. <id>, summary at <when>: it says <what it says>. Chapter <N> of the book says <what the text says>. Correct it.
7. The cards of the last chapters: <what is wrong>. Read chapters <N> to <M> in full and rewrite them.

Rebuild with:
python xray/authoring/tools/make_sidecar.py <work>/book.epub <work>/writer/<book-slug>.source.json -n <book-slug>
Report the builder's remaining notes and the number of entries.
```
