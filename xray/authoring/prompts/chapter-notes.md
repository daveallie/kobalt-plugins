# Prompt for the chapter notes

This is the prompt for step 2 of [Writing sidecars](../README.md#the-steps). It makes a model read one chapter and log who appears in it, under which names, and what the chapter establishes. The log is not a sidecar. A writer later composes the cards from the logs and from the book, as [writer.md](writer.md) describes.

Use it with a local model, a hosted model, or a reader agent. `xraygen` in [glaucon1984/kobalt-xray-sidecars](https://github.com/glaucon1984/kobalt-xray-sidecars) sends exactly these prompts, one call per chapter, and keeps each answer as `chapter-<number>.json`.

## The prompt

Two parts: the system message, then the user message. Replace what is in angle brackets. The instructions stay in English whatever the book's language; `<language>` is the language the answer must be written in, named outright (see the notes below).

System message:

```text
You log one chapter of a novel for a spoiler-safe character guide. Use ONLY the chapter text given. Do not use anything you know about the book from elsewhere, and never state anything the text does not say. Copy names exactly as spelled. The book is in <language>: write every sentence of your answer in <language>, in short, plain sentences.
```

User message:

```text
<Who is who so far, from earlier chapters. Use it only to recognise people: when somebody in this text is one of them, use exactly that name as "name"; do not repeat these lines as news.
<one line per person>

(leave this block out for the first chapter, or when there is no who-is-who)>

Chapter <number> of a novel follows between the markers.

1. people: every NAMED person or named entity (an AI, a spirit, a talking machine) that appears or is mentioned, including minor ones and people in flashbacks. Do not list unnamed people, companies, places or groups. For each:
- name: the fullest name the text uses (or the name from the who-is-who).
- name_forms: every way this text refers to them by name (first name, surname, nickname, title with name).
- in_person: true if they are present in a scene (also in a flashback or on a screen), false if only mentioned.
- first_sight: one short sentence: who they are when they first appear in this text, with nothing learned later in it.
- learned: one or two sentences with everything important this text establishes about them by its end: what they do, what happens to them, and above all anything revealed (who they really work for, a hidden role, a betrayal, a death). State as fact only what the text states as fact; when something is only suspected or claimed, say who suspects or claims it. Be sure who does what: do not give one person another person's actions.
- same_as: only when this text itself reveals that this person and somebody known under another name are one and the same individual, that other name; otherwise an empty string. Two people who merely talk to each other are not the same.
- relationships: their relations to other named people as this text states them; "with" is the other person's name and "text" a phrase of at most eight words from this person's side, such as "Brother" or "Employer, who distrusts him".
2. terms: invented technology, slang, organisations and places that belong to the novel's world and that a reader might want explained, each with what it means as far as this text shows. Leave out everyday words, real brands, foods and real cities.

<<<TEXT
<the chapter's text>
TEXT>>>
```

For a chapter read in parts, say "Part 2 of 5 of chapter 12 of a novel follows between the markers." in place of the first line.

## The answer

JSON only, in this shape. With a local model or an API, give it as a JSON schema, so that the server enforces the shape:

```json
{
  "people": [{
    "name": "Maren Holt",
    "name_forms": ["Maren", "Holt", "the Harbourmaster"],
    "in_person": true,
    "first_sight": "The harbourmaster, who meets the first boat in.",
    "learned": "She has been passing the harbour's ledgers to the Tidewardens. Corin suspects it.",
    "same_as": "",
    "relationships": [{ "with": "Corin Holt", "text": "Brother, who suspects her" }]
  }],
  "terms": [
    { "term": "Tidewardens", "meaning": "A guild that claims the right to set the tides' tables." }
  ]
}
```

All of `name`, `name_forms`, `in_person`, `first_sight`, `learned`, `same_as` and `relationships` are required for a person, and `term` and `meaning` for a term. The two lists may be empty.

## The variant for reader agents

A reader agent, such as a sub-agent of a coding agent, reads the chapters itself instead of being sent one. Give it the same rules, and add these:

- "terms" also covers brands, drugs, weapons and real-world references a reader may not know, not only invented words.
- A person who appears unnamed in the chapter but is recognisable from earlier chapters is listed under their name, with a note in "learned" that this chapter does not name them. The writer then knows not to list that chapter as a place where the reader can know who it was.
- Attribute every fact to the chapter whose text states it.
- Write in your own words. Do not copy sentences from the book.

Give each reader a run of chapters of about 20,000 to 25,000 words, and ask for one JSON file per chapter, named `chapter-001.json`, `chapter-002.json` and so on, in the shape above, so that the writer finds them in the same way whoever wrote them. Number the chapters by the list from `--chapters`, with the same `--chapter-pattern` and `--chapter-split`, so that the readers and the writer agree. Do not give a reader any cast list, timeline or glossary from the EPUB that stands outside the chapters. The builder's `Book(path).chapter_texts(pattern, split)` in [`../tools/make_sidecar.py`](../tools/make_sidecar.py) returns each chapter's number, label and paragraphs, as the chapter list counts them.

## Notes on using it

- One call per chapter.
- A chapter of more than about 6,000 words goes in parts, each logged by its own call and numbered as part of the chapter. Cut between paragraphs, which `--chapter-split` does, and `xraygen` reads a long chapter in parts of about 4,500 words.
- Weaker models need a short who-is-who of the earlier chapters: one line per person, with the name and who they are. Without it every local model I tried misread a chapter in which a caller on the phone was another character it had met before; with it, one of them read the chapter correctly. `xraygen` builds and sends one.
- State the output language outright, as in the system message. No local model wrote Spanish for a Spanish chapter when told "the language of the chapter".
- For a local model, turn thinking off and give the answer a small output budget, about 6,000 tokens. In thinking mode the model spent the whole budget on thoughts and the JSON came out cut short and broken. I ran local models with a context of 16,384 tokens.
- Ask for JSON by schema when the server supports it, and read the answers before relying on them. These logs are good on who appears and roughly what happens, and weaker on detail: expect one person credited with another's action, names given wrongly, organisations or job titles listed as people, ordinary words listed as terms, and wrong or missing `same_as`. The writer is told to check the book on all of these. See [benchmarks.md](../benchmarks.md#chapter-notes) for what each model did.
