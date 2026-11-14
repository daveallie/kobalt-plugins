"""Checks on an X-Ray source that the builder does not make.

    python check_source.py BOOK.epub SOURCE.json [--cards id,id,...] [--at 33,66,100] [--words N]

It builds the source with make_sidecar.py, which must be in the same folder, writes nothing, and
prints:

- the builder's own notes, counted by kind, with every error and every "does not occur",
  "would answer" and "first occurs" line;
- the entries whose first summary is at the end of a chapter ("eN"), which cannot be looked up in
  the chapter that introduces them;
- the words of names and the single-word aliases that occur in the book in lower case --words
  times or more (default 5), which means an ordinary word that will open the card everywhere;
- the later summaries that open like a change note ("now", "after", "later", and the same words
  in Spanish), which do not say who the entry is;
- with --cards, each named card as a reader sees it at the percentages of --at: the summary in
  force, the relationships in force and the place last seen.

The change-note words are English and Spanish; add the words of your language to CHANGE below.
Reading the later summaries yourself is still needed: this only catches the ones that open with
one of those words.
"""
import argparse
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_sidecar import Book, build  # noqa: E402

CHANGE = re.compile(r"^(ahora|tras|despu[eé]s|reci[eé]n|ya |luego|m[aá]s tarde|finalmente|al final|"
                    r"now|after|later|finally|then|having|no longer|still)\b", re.I)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("epub")
    parser.add_argument("source")
    parser.add_argument("--cards", default="", help="ids of the entries to print, separated by commas")
    parser.add_argument("--at", default="33,66,100", help="percentages at which to print the cards")
    parser.add_argument("--words", type=int, default=5, help="report words with this many lower-case occurrences")
    arguments = parser.parse_args()

    with open(arguments.source, encoding="utf-8") as file:
        source = json.load(file)
    book = Book(arguments.epub)
    problems = []
    sidecar = build(source, book, problems)
    entries = source["entries"]
    built = {character["id"]: character for character in sidecar["characters"]}
    print("%d entries, %d summaries, %d relationships, %d with \"seen\"" % (
        len(entries), sum(len(entry["summary"]) for entry in entries),
        sum(len(entry.get("relationships", [])) for entry in entries),
        sum(1 for entry in entries if entry.get("seen"))))

    kinds = {}
    for problem in problems:
        kind = ("note" if problem.startswith("note:") else "does not occur" if "does not occur" in problem
                else "first occurs" if "first occurs" in problem else "would answer" if "would answer" in problem else "other")
        kinds.setdefault(kind, []).append(problem)
    print("\nBuilder: " + (", ".join("%d %s" % (len(items), kind) for kind, items in sorted(kinds.items())) or "nothing"))
    for kind in ("other", "does not occur", "would answer", "first occurs"):
        for problem in kinds.get(kind, []):
            print("  " + problem)

    late = [entry["id"] for entry in entries
            if str(min(entry["summary"], key=lambda item: built_at(built, entry, item))["when"]).startswith("e")]
    print("\nEntries that begin at the end of a chapter: %d" % len(late))
    for name in late:
        print("  " + name)

    text = "\n".join(paragraph for _, _, paragraphs in book.chapter_texts(
        source.get("chapter_pattern", r"^(\d+)\b"), source.get("chapter_split")) for paragraph in paragraphs)
    counted = {}
    for entry in entries:
        words = []
        if " " not in entry["name"]:
            words += [(word, "name") for word in re.split(r"[ \t\n\r\f\v]+", entry["name"]) if word]
        for alias in entry.get("aliases", []):
            alias = alias if isinstance(alias, str) else alias["text"]
            if not re.search(r"\s", alias):
                words.append((alias, "alias"))
        for word, kind in words:
            key = re.sub(r"^\W+|\W+$", "", word).lower()
            if not key or (key, entry["id"]) in counted:
                continue
            lower = len(re.findall(r"(?<!\w)%s(?!\w)" % re.escape(key), text))
            total = len(re.findall(r"(?<!\w)%s(?!\w)" % re.escape(key), text, re.I))
            counted[(key, entry["id"])] = (lower, total, kind)
    ordinary = sorted(((lower, total, key, name, kind) for (key, name), (lower, total, kind) in counted.items()
                       if lower >= arguments.words), reverse=True)
    print("\nWords that occur in lower case %d times or more (lower / all, word, entry): %d" % (arguments.words, len(ordinary)))
    for lower, total, key, name, kind in ordinary:
        print("  %4d / %4d  %-22s %s (%s)" % (lower, total, key, name, kind))

    notes = []
    for entry in entries:
        items = sorted(entry["summary"], key=lambda item: built_at(built, entry, item))
        for item in items[1:]:
            if CHANGE.search(item["text"]):
                notes.append("  %s %s: %s" % (entry["id"], item["when"], item["text"][:110]))
    print("\nLater summaries that open like a change note: %d" % len(notes))
    for note in notes:
        print(note)

    points = [float(value) for value in arguments.at.split(",") if value]
    names = {entry["id"]: entry["name"].replace(" ", " ") for entry in entries}
    for name in [value for value in arguments.cards.split(",") if value]:
        character = built.get(name)
        if character is None:
            print("\n(no entry %r)" % name)
            continue
        print("\n=== %s (%s)" % (names[name], name))
        for point in points:
            summary = [item for item in character["summary"] if item["at"] <= point]
            print("--- at %g %%: %s" % (point, summary[-1]["text"] if summary else "(not known yet)"))
            latest = {}
            for item in character.get("relationships", []):
                if item["at"] <= point:
                    latest[item["with"]] = item["text"]
            for other, words in latest.items():
                print("      %s: %s" % (names.get(other, other), words))
            seen = [item["where"] for item in character.get("appearances", []) if item["at"] <= point]
            if seen:
                print("      last seen: %s" % seen[-1])


def built_at(built, entry, item):
    """The percentage the builder gave this summary: the texts are matched, since the built list is sorted."""
    for other in built[entry["id"]]["summary"]:
        if other["text"] == item["text"]:
            return other["at"]
    return 0.0


if __name__ == "__main__":
    main()
