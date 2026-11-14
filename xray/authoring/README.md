# Writing sidecars

This folder holds what I learned about making X-Ray sidecars for whole novels: a way to write them that keeps spoilers out, prompts for the models that help, a tool that computes the positions from the EPUB, and measurements of what each way of working costs and gives. The sidecar format itself is described in the [plugin README](../README.md).

## What a good sidecar needs

- Placement that does not spoil: a fact shows only once the reader has reached the chapter that states it.
- A card in the chapter that introduces someone or something, so that a reader can look a name up as soon as it appears, with only what that first page shows.
- Every word a reader might press: people, but also invented words, organisations, places and real-world references, under the forms the book uses, and with names that do not answer ordinary words.
- Summaries that stand alone: the card shows only the latest summary, so each one says who or what the entry is before it says what has happened.

## The idea that changes most

Do not write percentages. Write a *source* file by chapter, and let a small tool compute the percentages from the EPUB.

- A model knows which chapter reveals a fact. It does not know what percentage of the book that chapter ends at, and it cannot count words.
- Percentages belong to one edition. A different EPUB, with other front matter or an afterword, moves every one of them. A source that names chapters can be rebuilt for any edition.
- The tool can check the names against the book's text: a name that never occurs, a name that occurs before its entry is known, a name that would answer every "the".

An entry in a source looks like this. `s3` means "from the first page of chapter 3", `e7` means "from the last page of chapter 7", and `seen` lists the chapters where the person appears in person:

```json
{
  "book": { "title": "The Fifth Tide", "series": "Saltmarsh", "number": 5 },
  "entries": [{
    "id": "maren",
    "name": "Maren Holt",
    "aliases": ["Maren", "Holt", "the Harbourmaster"],
    "summary": [
      { "when": "s3",  "text": "Harbourmaster of Grey Quay, met on the quay as the first boats come in." },
      { "when": "e41", "text": "Harbourmaster of Grey Quay, now secretly allied with the Tidewardens." }
    ],
    "relationships": [{ "when": "e7", "with": "corin", "text": "Estranged brother" }],
    "seen": [3, 7, 18]
  }]
}
```

The commands, from the root of this repository. The first lists the chapters it finds with their percentages and word counts, the second builds the sidecar:

```sh
python xray/authoring/tools/make_sidecar.py "My Book.epub" --chapters
python xray/authoring/tools/make_sidecar.py "My Book.epub" my-book.source.json -n "My Book"
```

The result is `My Book.xray.json`, written beside the source unless you pass `-o <folder>`. The tool needs Python 3 and nothing else. The source format is defined in the docstring at the top of [`tools/make_sidecar.py`](tools/make_sidecar.py), and the rules for writing one are in [conventions.md](conventions.md).

## Choosing a route

Writing a source for a whole novel takes two kinds of work. Someone has to read every chapter and note who appears and what it reveals (the *chapter notes*), and someone has to write the cards from those notes and from the book (the *writer*). The routes below differ in who does which. None of them needs a GPU. Costs are in *agent tokens*, the total a coding agent reports for a sub-agent, which compares runs with each other and is not a bill; see [benchmarks.md](benchmarks.md).

| You have | Chapter notes | Source | Cost and quality | Measured |
| --- | --- | --- | --- | --- |
| (a) A coding agent such as Claude Code, or a similar tool, and nothing else | Reader sub-agents, about four for a novel | One writer agent | With Sonnet 5.5 for both steps: about 1.2 million agent tokens and 30 minutes for an 86,500-word novel, with about the accuracy of route (b). With Claude Fable 5.2 and a review afterwards it gave the fullest result I made, for 0.9 to 1.1 million agent tokens a book. See [benchmarks.md](benchmarks.md#whole-book-count-zero) | Yes |
| (b) A coding agent and a local model | The local model, for free | One writer agent | The cheapest route I measured that reaches the size and accuracy of the reviewed file: about 600,000 agent tokens and 22 minutes for an 86,500-word novel with a Sonnet 5.5 writer, plus 23 minutes of local model | Yes |
| (c) Only a local model | `xraygen` | `xraygen` | Free, and weaker: cards with wrong statements about who did what, and turning points that fade from later cards. 23 minutes for the same novel | Yes |
| (d) An API key for any hosted model with an OpenAI-compatible API | `xraygen --api openai --base-url ... --model ...`, or any of the above steps with that model | The same, or a writer agent | Not known. The protocol works, and the hosted model's own quality and price were not measured | Protocol only |
| (e) Only a chat app | | The [one-shot prompt](prompts/one-shot.md) | A draft whose percentages are estimates by the model | No |

Routes (a), (b) and (c) are measured. Route (d) was tested only for the protocol, against a local OpenAI-compatible endpoint, so I cannot say how well or at what price any hosted model does it. Route (e) is not measured at all.

About the local model: I ran it on one 24 GB GPU. A GPU is not needed for the other ways to get chapter notes (a hosted model, or reader agents), and I did not measure a local model on a machine without one.

`xraygen`, the generator that does the local-model and API steps, is not part of this repository. It is in [glaucon1984/kobalt-xray-sidecars](https://github.com/glaucon1984/kobalt-xray-sidecars), which also holds finished sidecars with their sources, and which you can use as examples. Clone it to run `python -m xraygen`.

## The steps

Work in a new folder of your own, `<work>`, and never inside this repository. Copy the EPUB there as `book.epub`. The builder writes its result next to the source, and the book's own folder may already hold a sidecar under the same name.

1. **Check the chapter list.** Run `python xray/authoring/tools/make_sidecar.py <work>/book.epub --chapters`. Each line is a chapter: its number, where it starts and ends in per cent, its words and its label. The list must show the story's sections and nothing else, and no chapter should be much over 6,000 words. If it does not, see [Books with unnumbered or very long chapters](#books-with-unnumbered-or-very-long-chapters). The numbers of this final list are the ones the notes and the source use.

2. **Chapter notes.** One call per chapter, with the prompt in [prompts/chapter-notes.md](prompts/chapter-notes.md): by reader agents (route a), or by a local or hosted model with `xraygen` (routes b to d):

   ```sh
   python -m xraygen <work>/book.epub -o <work> -n draft --host http://localhost:11434 --model <model> --language en
   ```

   Every answer is cached in `<work>/work-<hash>/`, so a stopped run goes on where it was when the same command is run again. What matters there are the `chapter-*.json` files, one per chapter. `xraygen` also writes its own draft, `draft.source.json`: that is the whole of route (c). On route (b), keep it as a fallback and do not give it to the writer. For a hosted model use `--api openai --base-url <api root> --model <model>`, with the key in the environment variable `OPENAI_API_KEY` (or the variable named by `--api-key-env`), never on the command line. If the model thinks before it answers, add `--reasoning-effort none` (or `low`): its thoughts otherwise use up the output limit and the answer is cut short. The run prints its calls, seconds and input and output tokens at the end, so you can price it.

   For a local model and a book with long chapters and a large cast, add `--context 24576`; see the notes in [prompts/chapter-notes.md](prompts/chapter-notes.md#notes-on-using-it). If a run stops on a chapter, run the same command again: the cache keeps every answer before it. If it stops on the same chapter again, look at what that chapter holds.

3. **The writer.** One agent reads the notes and the book and writes the source, builds it and works through the builder's notes. The brief and how to fill it in are in [prompts/writer.md](prompts/writer.md).

4. **Review.** The writer's report is not proof. Check its work with [tools/check_source.py](tools/check_source.py) and by reading, as [prompts/review.md](prompts/review.md) describes. Relationship wording had slips in every run.

5. **Correction pass.** Send what you found back to the same writer as a numbered list, then read the result again: a pass fixes what was listed and little else. Fix a single wording slip yourself, in the source, and rebuild. A pass took 2 to 9 minutes.

6. **Deliver.** The sidecar must carry the EPUB's file name with `.xray.json` in place of `.epub`, and sit beside the book on the device; see [Sidecar location](../README.md#sidecar-location). Build it under that name with `-n "<EPUB name without .epub>"`. Keep the `.source.json`: it is what lets you or someone else rebuild the sidecar for another edition.

## Books with unnumbered or very long chapters

By default the chapters are the entries of the EPUB's table of contents whose label begins with a number, and that number is the chapter number. When the labels are not numbered, or the book has few, long sections, two options fix the list. Pass them to `--chapters`, to `xraygen` and to the builder, or put them in the source, at its top level beside `"book"`, as `"chapter_pattern"` and `"chapter_split"`.

- `--chapter-pattern REGEX` chooses the table-of-contents entries that are chapters. Write a pattern that keeps the story and drops the rest: cover, title page, cast list, timeline, part title pages, about the author, credits, notes. A pattern with no number in it numbers the chapters from 1, so `'^(?!Cover|Cast|Timeline|About|Credits|Notes)'` keeps everything but the front and back matter. When the labels are numbered but do not begin with the number, such as "Chapter 12: Title", put the number in a group: `'^Chapter (\d+)'` keeps the book's own numbering, and drops a cast list or a lexicon at the back with it. When the chapters are titled in words, keep them by those words, with prefixes for the compounds. For a Spanish book whose chapters run from "Uno" to "Cuarenta y nueve" this worked: `'^(Prólogo|Epílogo|Uno|Dos|Tres|Cuatro|Cinco|Seis|Siete|Ocho|Nueve|Diez|Once|Doce|Trece|Catorce|Quince|Dieci|Veint|Treinta|Cuarenta)'`. `--chapter-pattern '^'` lists every entry, to see what there is. A cast list or a timeline must never be a chapter: it gives the book away to a model that reads it as a chapter.
- `--chapter-split 4500` cuts every chapter of more than about 4,500 words into parts between paragraphs, labelled like "Title (3/15)", and numbers all chapters from 1. Use it whenever a chapter is over about 6,000 words. A fact can only be placed at a chapter's first or last page, so a section of a third of the book would leave its cards a third of the book behind. The cuts depend only on the book and the number, so they are the same in every command.

## Series

For a later book of a series, give the writer the source of the earlier book as its example, and say what the series note in [prompts/writer.md](prompts/writer.md) says. What the earlier books established may go in at `when: 0`, reworded, when it occurs in this book. Never attach it to a character who appears here under another name until this book's text makes the link. Read the `when: 0` texts afterwards: they drift into what this book tells in its first chapters.

## Other languages than English

Name the language outright, in the prompt to the notes model and in the brief to the writer. No model I tried followed "write in the language of the chapter": given a Spanish chapter, every local model answered in English. With the language named, they wrote Spanish, with the translation's own terms. The prompts here are in English whatever the book's language. `xraygen --language` takes a code (`en`, `es`, `fr`, `de`, `it`, `pt`, `ca`, `nl`, `gl`, `eu`); any other code falls back to English. Names and aliases in the source must be the forms printed in the edition you have, because that is what the reader presses.

## Limits

- Sidecars made by route (b) had not yet been tried on a device when this was written. The reviewed ones, made by route (a) and then reviewed for spoiler timing, had.
- Only one book, Count Zero, has a reviewed source to score against. The longer books were checked by building them and reading a sample of cards against the text.
- A writer reads only part of a long book in full: about half of a 195,000-word book, about a sixth of a 243,500-word one, about 12 % of a 240,000-word one. It takes the rest from the notes and from searches, so the faults that remain are in the places it did not read. In one book that was the ending. The brief now asks for the last chapters to be read in full, and in the next long book the ending came out right; the review still reads the ending against the book.
- Each of the seven longer books needed at least one correction pass, in English as in Spanish. Count on it.
- Hosted models other than Claude were not measured, and neither was the cost in money of a hosted API.

All the numbers are in [benchmarks.md](benchmarks.md).
