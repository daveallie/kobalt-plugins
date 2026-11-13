# One-shot prompt

This is for people with only a chat app, route (e) of [Writing sidecars](../README.md#choosing-a-route). It asks a model to write the sidecar directly, percentages included, in one go. It is the prompt that the plugin README used to carry, with the rules I learned that do not need the builder.

I did not measure this prompt. I did not score its results, so I cannot say what quality to expect. Its weak point is the percentages. A model does not know what percentage of the book a chapter ends at, and it cannot count words, so every `at` it writes is an estimate. That is why the prompt keeps the plugin README's rule of [placing a fact at the end of the chapter](../../README.md#the-at-rule) that reveals it, which absorbs some of the error, and why an introduction here is also placed at the end of its chapter: a card can only be looked up from the end of the chapter that introduces it, not from its first page. The routes that use the builder do better on both counts, and they cost more effort. See [conventions.md](../conventions.md#introductions-at-the-start-reveals-at-the-end).

## How to use it

1. Give the model the prompt below together with the book text, or with notes on each chapter if the whole book does not fit. Fill in `<language>` with the language of the book, named outright: a model does not reliably follow "the language of the book".
2. Save the answer as the sidecar, named after the book file, as described under [Sidecar location](../../README.md#sidecar-location).
3. Validate it as [Validate a sidecar](../../README.md#validate-a-sidecar) describes.
4. Fix the percentages. List the chapters of your EPUB with their real percentages, with `python xray/authoring/tools/make_sidecar.py "My Book.epub" --chapters`, and correct each `at` to the end of its chapter. This replaces the model's estimates with the real values, and it does not need the model.

## The prompt

```text
Write an X-Ray sidecar for the attached book as JSON only, with no other text. Write every text in <language>, and use the names and terms exactly as this edition of the book spells them.

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
- Every entry needs a summary entry at the end of the chapter that introduces it. Its earliest summary decides when it becomes known, so never put a summary earlier than the introduction.
- Entries are people and also the terms of the book: invented words and technology, slang, organisations and brands, drugs and weapons, places of the story, historical and real-world references a reader may not know. A term is an entry with a summary and nothing else. Cover every named person, however minor, and every term a reader might hold a finger on and want explained. Do not add ordinary words or things nobody would look up.
- Every summary must stand alone. The card shows only the latest summary whose "at" has been reached, so every summary, including every later one, begins with who or what the entry is, in a short clause that gives nothing away (such as profession and role), and then gives the state at that point. Write it as the full picture at that point, never as a change note such as "Now he is dead".
- Add a later summary entry whenever something important about the entry is revealed, and keep updating the main characters to the last chapter of the book.
- A relationship is a person's relation to another entry in the file. On the card it reads "<other name>: <text>", so the text says what the other one is to this person. Add a new entry with a later "at" when the relationship changes or ends, and use the other entry's "id" in "with". A relationship stays on the card until a later one replaces it, so word it to stay true ("boss who hired her", not "boss who hires her today"), and do not make one out of a single incident.
- "appearances" lists where the character was seen in person, one entry per chapter that matters. "where" names the chapter.
- Never reveal anything before its "at". Do not mention events or identities that come later in a summary, relationship or appearance written for an earlier "at".
- Keep texts short, plain and free of markup, and in your own words: do not copy sentences from the book.
- A long press selects a single word, and an alias only matches as a whole. List single-word aliases (first name, surname, nickname, title, plural) as well as longer ones such as "Captain Maren".
- Keep "name" plain, and never put a common word in it: every word of "name" can be pressed, so "New Yen" would answer every "new" and "Pan Han" every "han". Name the entry "Yen" and put "New Yen" in "aliases". For the same reason never give an alias that is a common word, such as "the Place" or "the well", unless the word nearly always means that entry in this book.
- "name" and every plain string alias must be names the reader can link to the character at the point of introduction. "name" also appears in other characters' relationships, so it must never give away a secret.
- A secret identity stays a separate entry until the reveal. Alternatively, write the revealing alias as an object, { "text": "the alias", "at": <reveal percentage> }, so it matches only from the reveal on.
- A figure inside a simulation, a game, a recording or a story told within the book is not a person of the main story: say which it is, and do not write that something happened to the person when it happened to their image.
- Never use null in the JSON.
- Make every "id" unique.
```

## What I changed from the plugin README's version

- The entries are not only characters. Terms are entries too, with a summary and nothing else, so a reader can look up an invented word or an organisation.
- Every summary stands alone, so the card tells a reader who the person is at any point.
- Relationships are worded so that they stay true, because one stays on the card until a later one replaces it.
- Names avoid common words, and aliases include single words.
- The language of the book is named.
- Two more rules from [conventions.md](../conventions.md): write in your own words, and keep figures inside simulations or stories apart from the people of the book.
