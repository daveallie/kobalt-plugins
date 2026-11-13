#!/usr/bin/env python3
"""Build a Kobalt X-Ray sidecar (kobalt-xray/1) from a source file written by chapter.

The X-Ray plugin wants every fact placed at a percentage of the book by word count. Writing
those by hand is error-prone and they change with the edition, so the source file names
chapters instead and this tool works the percentages out from the EPUB itself, the way Kobalt
does (src/plugins/plugin_position.h: the words before a chapter plus the share of the chapter
that has been read, over all the words of the book).

    python make_sidecar.py BOOK.epub SOURCE.json            # writes BOOK.xray.json beside SOURCE
    python make_sidecar.py BOOK.epub SOURCE.json -o FOLDER  # ... into FOLDER
    python make_sidecar.py BOOK.epub SOURCE.json -n NAME    # ... as NAME.xray.json
    python make_sidecar.py BOOK.epub --chapters             # only list chapters and percentages

Copy the result beside the book on the device, named after the book file without its last
extension: "Count Zero.epub" takes "Count Zero.xray.json" (the default name of the result).

Source format (JSON):

    {
      "book": { "title": "...", "series": "...", "number": 2 },
      "chapter_pattern": "^(\\d+)\\b",          optional, see below
      "entries": [
        {
          "id": "turner", "name": "Turner",
          "aliases": ["the mercenary", { "text": "a secret name", "when": "e20" }],
          "summary": [ { "when": "s1", "text": "..." }, { "when": "e14", "text": "..." } ],
          "relationships": [ { "when": "e7", "with": "conroy", "text": "..." } ],
          "seen": [1, 4, 7]
        }
      ]
    }

"when" is where a fact becomes visible:
    0       from the start of the book (what earlier books of a series told)
    "s7"    from the first page of chapter 7: for introductions that say nothing the first
            pages of the chapter do not
    "e7"    from the last page of chapter 7: the plugin's rule for everything a chapter
            reveals, so nothing shows before the chapter has been read
    12.5    a percentage, as it is
"seen" lists the chapters in which the entry appears; each becomes a "Last seen" line that
shows once that chapter is finished.

Chapters are the entries of the book's table of contents whose label matches
"chapter_pattern" (default: a leading number, which is the chapter number). When no label
matches, every entry of the table of contents is a chapter, numbered from 1. A pattern
without a group numbers the matching entries from 1, so a pattern such as
"^(?!Cover|Notes|About)" keeps everything but the front and back matter.

A book whose table of contents has few, long sections gives cards that lag: a fact can only
be placed at a section's first or last page. "chapter_split": 4500 in the source (or
--chapter-split 4500) cuts every section of more than about that many words into parts
between paragraphs and numbers all chapters from 1 in reading order; --chapters with the
same option lists them. The source must then keep the same "chapter_pattern" and
"chapter_split", because its chapter numbers depend on both.

Only the Python standard library is used.
"""
import argparse
import html
import json
import math
import os
import posixpath
import re
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zipfile

FORMAT = "kobalt-xray/1"
# A fact for the end of a chapter shows this much (percent of the book) before the computed
# end, so that a small difference with Kobalt's own word count cannot push it to the next
# chapter's first page. 0.15 % of a novel is about half a page.
END_MARGIN = 0.15
STOPWORDS = {"the", "a", "an", "of", "and", "or", "in", "on", "at", "to", "de", "la", "le", "du", "von", "van"}
NS = {
    "c": "urn:oasis:names:tc:opendocument:xmlns:container",
    "o": "http://www.idpf.org/2007/opf",
    "n": "http://www.daisy.org/z3986/2005/ncx/",
    "x": "http://www.w3.org/1999/xhtml",
    "e": "http://www.idpf.org/2007/ops",
}


def plain_text(markup):
    body = re.search(r"<body[^>]*>(.*)</body>", markup, re.S | re.I)
    markup = body.group(1) if body else markup
    markup = re.sub(r"<(script|style)\b[^>]*>.*?</\1>", " ", markup, flags=re.S | re.I)
    # Only a block or a line break ends a word: "<span>T</span>urner" is one word.
    markup = re.sub(r"</?(p|div|h[1-6]|li|ul|ol|dl|dt|dd|tr|td|th|table|blockquote|section|article|aside|header|"
                    r"footer|figure|figcaption|pre|hr|br|img|nav|body)\b[^>]*>", " ", markup, flags=re.I)
    markup = re.sub(r"<[^>]+>", "", markup)
    return html.unescape(markup).replace("\xa0", " ")


def words_in(markup):
    return len(plain_text(markup).split())


def paragraphs_of(markup):
    """The text of one file as paragraphs, in reading order, case and punctuation kept."""
    body = re.search(r"<body[^>]*>(.*)</body>", markup, re.S | re.I)
    markup = body.group(1) if body else markup
    markup = re.sub(r"<(script|style)\b[^>]*>.*?</\1>", " ", markup, flags=re.S | re.I)
    markup = re.sub(r"</?(p|div|h[1-6]|li|ul|ol|dl|dt|dd|tr|table|blockquote|section|article|aside|header|"
                    r"footer|figure|figcaption|pre|hr|br|nav|body)\b[^>]*>", "\n", markup, flags=re.I)
    markup = re.sub(r"</?(td|th|img)\b[^>]*>", " ", markup, flags=re.I)
    markup = re.sub(r"<[^>]+>", "", markup)
    text = html.unescape(markup).replace("\xa0", " ")
    return [" ".join(line.split()) for line in text.split("\n") if line.strip()]


class Book:
    """Spine files with their word counts, and the table of contents."""

    def __init__(self, path):
        self.archive = zipfile.ZipFile(path)
        container = ET.fromstring(self.archive.read("META-INF/container.xml"))
        self.opf_path = container.find(".//c:rootfile", NS).get("full-path")
        self.base = posixpath.dirname(self.opf_path)
        opf = ET.fromstring(self.archive.read(self.opf_path))
        manifest = {}
        for item in opf.findall(".//o:manifest/o:item", NS):
            manifest[item.get("id")] = item
        self.files, self.markup, self.words = [], {}, {}
        for ref in opf.findall(".//o:spine/o:itemref", NS):
            item = manifest.get(ref.get("idref"))
            if item is None:
                continue
            name = self.resolve(item.get("href"))
            self.files.append(name)
            self.markup[name] = self.archive.read(name).decode("utf-8", errors="replace")
            self.words[name] = words_in(self.markup[name])
        self.total = sum(self.words.values())
        self.before = {}
        running = 0
        for name in self.files:
            self.before[name] = running
            running += self.words[name]
        self.toc = self.read_toc(opf, manifest)

    def resolve(self, href, base=None):
        href = urllib.parse.unquote(href)
        return posixpath.normpath(posixpath.join(self.base if base is None else base, href))

    def read_toc(self, opf, manifest):
        """(label, file, fragment) in reading order; the EPUB 3 nav first, else the NCX."""
        entries = []
        nav = next((i for i in manifest.values() if "nav" in (i.get("properties") or "").split()), None)
        if nav is not None:
            name = self.resolve(nav.get("href"))
            tree = ET.fromstring(self.archive.read(name))
            for element in tree.iter("{%s}nav" % NS["x"]):
                if element.get("{%s}type" % NS["e"]) == "toc":
                    for link in element.iter("{%s}a" % NS["x"]):
                        label = " ".join("".join(link.itertext()).split())
                        entries.append((label, link.get("href") or "", posixpath.dirname(name)))
        if not entries:
            spine = opf.find(".//o:spine", NS)
            ncx = manifest.get(spine.get("toc")) if spine is not None and spine.get("toc") else None
            if ncx is None:
                ncx = next((i for i in manifest.values() if i.get("media-type") == "application/x-dtbncx+xml"), None)
            if ncx is not None:
                name = self.resolve(ncx.get("href"))
                tree = ET.fromstring(self.archive.read(name))
                nav_map = tree.find("n:navMap", NS)
                for point in (nav_map.iter("{%s}navPoint" % NS["n"]) if nav_map is not None else []):
                    label = " ".join("".join(point.find("n:navLabel", NS).itertext()).split())
                    entries.append((label, point.find("n:content", NS).get("src") or "", posixpath.dirname(name)))
        result = []
        for label, href, base in entries:
            target, _, fragment = href.partition("#")
            result.append((label, self.resolve(target, base), fragment))
        return result

    def offset(self, name, fragment):
        """Words of the book before this place."""
        if name not in self.before:
            return None
        start = self.before[name]
        if fragment:
            match = re.search(r"""\bid\s*=\s*["']%s["']""" % re.escape(fragment), self.markup[name])
            if match:
                tag = self.markup[name].rfind("<", 0, match.start())
                start += words_in("<body>" + self.markup[name][:tag] + "</body>") if "<body" not in self.markup[name][:tag].lower() \
                    else words_in(self.markup[name][:tag] + "</body>")
        return start

    def chapters(self, pattern, split=None):
        """[(number, label, start %, end %)]; a chapter ends where the next toc entry starts."""
        return [(number, label, 100.0 * start / self.total, 100.0 * end / self.total)
                for number, label, start, end in self.chapter_spans(pattern, split)]

    def placed(self):
        """[(words of the book before it, paragraph)] for every paragraph, in reading order."""
        if not hasattr(self, "_placed"):
            self._placed = []
            for name in self.files:
                offset = self.before[name]
                for paragraph in paragraphs_of(self.markup[name]):
                    self._placed.append((offset, paragraph))
                    offset += len(paragraph.split())
        return self._placed

    def chapter_texts(self, pattern, split=None):
        """[(number, label, [paragraph, ...])] with the text as printed, for reading a chapter."""
        placed = self.placed()
        result = []
        for number, label, start, end in self.chapter_spans(pattern, split):
            result.append((number, label, [text for offset, text in placed if start <= offset < end]))
        return result

    def split_spans(self, spans, limit):
        """Cut every span of more than about `limit` words into parts between paragraphs, and number
        all of them from 1 in reading order. A part begins after a scene break ("* * *") when one is
        near the even cut, else at the nearest paragraph. The cuts depend only on the book and
        `limit`, so a source written against them builds the same way every time."""
        placed = self.placed()
        starts = [offset for offset, _ in placed]
        breaks = [placed[index + 1][0] for index in range(len(placed) - 1)
                  if not re.search(r"\w", placed[index][1])]
        pieces = []
        for _, label, start, end in spans:
            words = end - start
            if words <= limit * 1.3:
                pieces.append((label, start, end))
                continue
            count = -(-words // limit)
            cuts = [start]
            for index in range(1, count):
                ideal = start + words * index / float(count)
                reach = words / float(count) / 4
                low = cuts[-1]
                near = [offset for offset in breaks if low < offset < end and abs(offset - ideal) <= reach]
                if not near:
                    near = [offset for offset in starts if low < offset < end]
                if near:
                    cuts.append(min(near, key=lambda offset: abs(offset - ideal)))
            cuts.append(end)
            for index in range(len(cuts) - 1):
                pieces.append(("%s (%d/%d)" % (label, index + 1, len(cuts) - 1), cuts[index], cuts[index + 1]))
        return [(index + 1, label, start, end) for index, (label, start, end) in enumerate(pieces)]

    def chapter_spans(self, pattern, split=None):
        """[(number, label, first word, word after the last)], counted in words of the book.
        With `split`, see split_spans."""
        spans = self.toc_spans(pattern)
        return self.split_spans(spans, split) if split else spans

    def toc_spans(self, pattern):
        """The table of contents as [(number, label, first word, word after the last)]."""
        places = []
        for label, name, fragment in self.toc:
            start = self.offset(name, fragment)
            if start is not None:
                places.append((start, label))
        places.sort(key=lambda place: place[0])
        matcher = re.compile(pattern)
        matches = [matcher.search(label) for _, label in places]
        numbered = [bool(match) for match in matches]
        # The first group is the chapter number only when it is a number in every matching label;
        # a pattern such as "^(Prologue|Year)" just picks the entries, numbered from 1.
        by_group = all(match.groups() and (match.group(1) or "").isdigit() for match in matches if match)
        result = []
        for index, (start, label) in enumerate(places):
            end = places[index + 1][0] if index + 1 < len(places) else self.total
            match = matches[index]
            if any(numbered):
                if not match:
                    continue
                number = int(match.group(1)) if by_group else len(result) + 1
            else:
                number = index + 1
            result.append((number, label, start, end))
        return result

    def metadata(self):
        """Title, author and language as the OPF gives them."""
        opf = ET.fromstring(self.archive.read(self.opf_path))
        found = {}
        for tag in ("title", "creator", "language"):
            node = opf.find(".//{http://purl.org/dc/elements/1.1/}" + tag)
            found[tag] = (node.text or "").strip() if node is not None else ""
        return found

    def text_by_chapter(self, chapters, split=None):
        """{chapter number: lower-case text} for the name checks: by whole spine files, or by
        paragraphs when the chapters are parts cut by `split` (several may share one file)."""
        result = {}
        if split:
            placed = self.placed()
            for number, _, start, end in chapters:
                first, last = start * self.total / 100.0 - 0.5, end * self.total / 100.0 - 0.5
                result[number] = " ".join(text for offset, text in placed if first <= offset < last).lower()
            return result
        for number, _, start, end in chapters:
            parts = []
            for name in self.files:
                middle = 100.0 * (self.before[name] + self.words[name] / 2.0) / self.total
                if start <= middle < end:
                    parts.append(plain_text(self.markup[name]))
            result[number] = " ".join(" ".join(parts).split()).lower()
        return result


class Positions:
    def __init__(self, chapters):
        self.start = {number: start for number, _, start, _ in chapters}
        self.end = {number: end for number, _, _, end in chapters}
        self.label = {number: label for number, label, _, _ in chapters}

    def at(self, when, where):
        if isinstance(when, bool):
            raise ValueError("%s: 'when' cannot be true or false" % where)
        if isinstance(when, (int, float)):
            if not 0 <= when <= 100:
                raise ValueError("%s: percentage %r is outside 0 to 100" % (where, when))
            return when
        match = re.fullmatch(r"([se])(\d+)", str(when))
        if not match:
            raise ValueError("%s: 'when' is %r; use 0, a percentage, \"s<chapter>\" or \"e<chapter>\"" % (where, when))
        chapter = int(match.group(2))
        if chapter not in self.start:
            raise ValueError("%s: the book has no chapter %d" % (where, chapter))
        # Rounded up, so the last page of the chapter before does not reach it.
        start = min(100.0, math.ceil(self.start[chapter] * 100 + 1) / 100.0)
        if match.group(1) == "s":
            return start
        # A chapter shorter than the margin (a page or less) would end before it starts, and show
        # what it reveals on the chapter before: its end is then its start.
        return max(start, math.floor((self.end[chapter] - END_MARGIN) * 100) / 100.0)

    def chapter_of(self, when):
        match = re.fullmatch(r"[se](\d+)", str(when))
        return int(match.group(1)) if match else 0


def normalise(text):
    text = text.lower().strip(" \t.,;:!?\"'()[]‘’“”–—-")
    return re.sub(r"(’|')s$", "", text)


def build(source, book, problems):
    split = source.get("chapter_split")
    if split is not None and (isinstance(split, bool) or not isinstance(split, int) or split < 500):
        raise ValueError("\"chapter_split\" must be a number of words, 500 or more")
    chapters = book.chapters(source.get("chapter_pattern", r"^(\d+)\b"), split)
    if not chapters:
        raise ValueError("no chapters found in the book's table of contents")
    positions = Positions(chapters)
    text = book.text_by_chapter(chapters, split)
    ids, characters, keys = set(), [], {}
    entries = source.get("entries")
    if not isinstance(entries, list):
        raise ValueError("the source has no \"entries\" list")
    for entry in entries:
        where = "entry %r" % (entry.get("id"),)
        if not entry.get("id") or not entry.get("name"):
            raise ValueError("%s: every entry needs an id and a name" % where)
        if entry["id"] in ids:
            raise ValueError("%s: this id is used twice" % where)
        ids.add(entry["id"])
        if not entry.get("summary"):
            raise ValueError("%s: no summary" % where)
        character = {"id": entry["id"], "name": entry["name"]}
        first = None
        # As the plugin does: the name's words are split at ASCII white space only, so a name
        # written with no-break spaces ("People\u00a0of\u00a0Importance") is one key, never "of".
        words = [word for word in re.split(r"[ \t\n\r\f\v]+", entry["name"]) if word]
        names = [(entry["name"], None)] + [(word, None) for word in words]
        aliases = []
        for alias in entry.get("aliases", []):
            if isinstance(alias, str):
                aliases.append(alias)
                names.append((alias, None))
            else:
                at = positions.at(alias["when"], where + " alias " + alias["text"])
                aliases.append({"text": alias["text"], "at": at})
                names.append((alias["text"], positions.chapter_of(alias["when"])))
        if aliases:
            character["aliases"] = aliases
        summary = []
        for item in entry["summary"]:
            at = positions.at(item["when"], where + " summary")
            summary.append({"at": at, "text": item["text"]})
            first = at if first is None else min(first, at)
        character["summary"] = sorted(summary, key=lambda item: item["at"])
        introduced = min(positions.chapter_of(item["when"]) for item in entry["summary"])
        relationships = []
        for item in entry.get("relationships", []):
            relationships.append({"at": positions.at(item["when"], where + " relationship"), "with": item["with"],
                                  "text": item["text"]})
        if relationships:
            character["relationships"] = relationships
        seen = []
        for chapter in entry.get("seen", []):
            label = positions.label.get(chapter)
            if label is None:
                raise ValueError("%s: \"seen\" names chapter %r, which the book does not have" % (where, chapter))
            title = re.sub(r"^\d+\W*", "", label).strip()
            seen.append({"at": positions.at("e%d" % chapter, where), "where": "Ch. %d, %s" % (chapter, title) if title else "Ch. %d" % chapter})
        if seen:
            character["appearances"] = seen
        characters.append(character)

        # Checks that need the text: each name should occur in the book, and not before the
        # entry is known (a name that can be held before then just gets no card).
        checked = set()
        for name, since in names:
            key = normalise(name)
            # A name written with no-break spaces is for display only; its aliases are checked.
            if not key or key in checked or "\u00a0" in name:
                continue
            checked.add(key)
            if key in STOPWORDS:
                problems.append("%s: the name word %r would answer every %r in the book; move the epithet to an alias" % (where, name, key))
                continue
            keys.setdefault(key, []).append(entry["id"])
            pattern = re.compile(r"(?<!\w)%s(?!\w)" % re.escape(key))
            found = [number for number in sorted(text) if pattern.search(text[number])]
            bare = re.sub(r"^the\s+", "", key)
            if not found and bare != key:
                found = [number for number in sorted(text) if re.search(r"(?<!\w)%s(?!\w)" % re.escape(bare), text[number])]
            if not found:
                problems.append("%s: %r does not occur in the book" % (where, name))
            elif since is None and introduced and found[0] < introduced and " " not in key:
                problems.append("%s: %r first occurs in chapter %d, before the entry is known (chapter %d)"
                                % (where, name, found[0], introduced))
    for character in characters:
        for item in character.get("relationships", []):
            if item["with"] not in ids:
                raise ValueError("entry %r: relationship with unknown id %r" % (character["id"], item["with"]))
    shared = {key: owners for key, owners in keys.items() if len(set(owners)) > 1}
    for key in sorted(shared):
        problems.append("note: %r answers for %s (they stack in one card)" % (key, ", ".join(sorted(set(shared[key])))))
    result = {"format": FORMAT}
    if isinstance(source.get("book"), dict):
        result["book"] = source["book"]
    result["characters"] = characters
    return result


def no_nulls(value, where="sidecar"):
    if value is None:
        raise ValueError("%s holds null, which the plugin cannot read" % where)
    if isinstance(value, dict):
        for key, item in value.items():
            no_nulls(item, where + "." + key)
    elif isinstance(value, list):
        for index, item in enumerate(value):
            no_nulls(item, "%s[%d]" % (where, index))


def main():
    parser = argparse.ArgumentParser(description="Build a Kobalt X-Ray sidecar from a chapter-based source.")
    parser.add_argument("epub")
    parser.add_argument("source", nargs="?")
    parser.add_argument("-o", "--output", help="folder for the sidecar (default: the source's folder)")
    parser.add_argument("-n", "--name", help="name of the sidecar without .xray.json (default: the EPUB's file name)")
    parser.add_argument("--chapters", action="store_true", help="list the chapters with their percentages and stop")
    parser.add_argument("--chapter-pattern", default=None, help="regular expression for chapter labels in the table of contents")
    parser.add_argument("--chapter-split", type=int, default=None, metavar="WORDS",
                        help="cut chapters longer than about this many words into parts, and number all from 1")
    arguments = parser.parse_args()
    book = Book(arguments.epub)
    if arguments.chapters or not arguments.source:
        for number, label, start, end in book.chapters(arguments.chapter_pattern or r"^(\d+)\b", arguments.chapter_split):
            print("%3d  %6.2f - %6.2f  %6d  %s" % (number, start, end, round((end - start) * book.total / 100.0), label))
        print("%d words" % book.total)
        return 0
    with open(arguments.source, encoding="utf-8") as handle:
        source = json.load(handle)
    if arguments.chapter_pattern:
        source["chapter_pattern"] = arguments.chapter_pattern
    if arguments.chapter_split:
        source["chapter_split"] = arguments.chapter_split
    problems = []
    try:
        sidecar = build(source, book, problems)
        no_nulls(sidecar)
    except (ValueError, KeyError) as error:
        print("error: %s" % error, file=sys.stderr)
        return 1
    folder = arguments.output or os.path.dirname(os.path.abspath(arguments.source))
    name = (arguments.name or os.path.splitext(os.path.basename(arguments.epub))[0]) + ".xray.json"
    target = os.path.join(folder, name)
    with open(target, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(sidecar, handle, ensure_ascii=False, indent=1)
        handle.write("\n")
    for problem in problems:
        print(problem)
    print("%s: %d entries, %d bytes" % (target, len(sidecar["characters"]), os.path.getsize(target)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
