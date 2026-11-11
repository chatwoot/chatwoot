#!/usr/bin/env python3
"""Check a knowledge-base dataset (CSV or JSON Lines) before import.

Each row must be a FAQ (question + answer) or a document (title + content),
with a unique id. Errors make the exit code 1; warnings do not.

Several files (one per sheet tab) are checked one by one and then together:
an id used in more than one file, or near-duplicate questions or titles in
different files, are reported "across files".

Usage: check_dataset.py FILE [FILE ...] [--today YYYY-MM-DD] [--max-rows N] [--alias NAME=column ...] [--json]
Standard library only.
"""
import argparse
import csv
import datetime as dt
import io
import json
import re
import sys

ALIASES = {"text": "content", "body": "content", "end_date": "last_day"}
KNOWN = {"id", "question", "answer", "title", "content", "category", "section", "start_date", "last_day"}
LONG_ANSWER = 1200  # characters; FAQ answers this long usually hold several facts
DUP_SIMILARITY = 0.8
DANGLING = re.compile(r"\b(see above|as mentioned|as above|see below|the above)\b", re.I)


def norm_key(k):
    k = (k or "").strip().lower().lstrip("﻿")
    return ALIASES.get(k, k)


def read_rows(path):
    with open(path, "rb") as f:
        raw = f.read().decode("utf-8-sig")
    if path.lower().endswith((".jsonl", ".ndjson")):
        rows = []
        for n, line in enumerate(raw.splitlines(), 1):
            if not line.strip():
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError as e:
                rows.append((n, None, f"line is not valid JSON: {e.msg}"))
                continue
            if not isinstance(obj, dict):
                rows.append((n, None, "line is not a JSON object"))
                continue
            rows.append((n, {norm_key(k): "" if v is None else str(v) for k, v in obj.items()}, None))
        return rows
    reader = csv.DictReader(io.StringIO(raw))
    reader.fieldnames = [norm_key(f) for f in (reader.fieldnames or [])]
    return [(n, {k: (v or "") for k, v in r.items() if k}, None) for n, r in enumerate(reader, 2)]


def parse_day(s):
    try:
        return dt.date.fromisoformat(s)
    except ValueError:
        return None


def bigrams(s):
    s = re.sub(r"[\W_]+", "", s.lower())
    return {s[i:i + 2] for i in range(len(s) - 1)} or {s}


def similarity(a, b):
    x, y = bigrams(a), bigrams(b)
    return len(x & y) / len(x | y) if x | y else 0.0


def check(path, today, max_rows, extra=None):
    errors, warnings, faqs, docs, dated = [], [], 0, 0, 0
    ALIASES.update(extra or {})
    rows = read_rows(path)
    columns = sorted({k for _, r, _ in rows if r for k in r} - KNOWN)
    if columns:
        warnings.append((0, "columns not checked: " + ", ".join(columns)
                         + " (if one is a question/answer/title/content/date column under another name, use --alias NAME=column)"))
    seen, heads, numbered = {}, [], []
    for line, r, problem in rows:
        if problem:
            errors.append((line, problem))
            continue
        rid = r.get("id", "").strip()
        if not rid:
            errors.append((line, "missing id"))
        elif rid in seen:
            errors.append((line, f"duplicate id {rid!r} (first on line {seen[rid]})"))
        else:
            seen[rid] = line
            if rid.isdigit():
                numbered.append(line)
        q, a = r.get("question", "").strip(), r.get("answer", "").strip()
        t, c = r.get("title", "").strip(), r.get("content", "").strip()
        if not t:  # importers commonly build a title from category and section
            t = ": ".join(x for x in (r.get("category", "").strip(), r.get("section", "").strip()) if x)
        if q and a:
            faqs += 1
            head, body = q, a
            if t or c:
                warnings.append((line, "has both question/answer and title/content; the importer may use only one pair"))
            if len(a) > LONG_ANSWER:
                warnings.append((line, f"answer is {len(a)} characters; split it into one fact per row"))
        elif c:
            docs += 1
            head, body = t, c
            if not t:
                warnings.append((line, "document has no title; the importer may invent one"))
        else:
            errors.append((line, "neither a FAQ (question + answer) nor a document (content)"))
            continue
        if DANGLING.search(body):
            warnings.append((line, "refers to other rows ('see above'...); a retrieved row arrives alone"))
        start_s, last_s = r.get("start_date", "").strip(), r.get("last_day", "").strip()
        start = parse_day(start_s) if start_s else None
        last = parse_day(last_s) if last_s else None
        if start_s and not start:
            errors.append((line, f"start_date {start_s!r} is not YYYY-MM-DD"))
        if last_s and not last:
            errors.append((line, f"last_day {last_s!r} is not YYYY-MM-DD"))
        if start and last and last < start:
            errors.append((line, "last_day is before start_date"))
        if last:
            dated += 1
            if last < today:
                warnings.append((line, f"expired on {last_s}; the bot will not use it"))
        if head:
            heads.append((line, head))
    for i, (la, ha) in enumerate(heads):
        for lb, hb in heads[i + 1:]:
            if similarity(ha, hb) >= DUP_SIMILARITY:
                warnings.append((lb, f"very similar to line {la}: {ha!r} / {hb!r}; merge or make them distinct"))
    if numbered:
        warnings.append((0, f"{len(numbered)} ids are plain numbers (lines {', '.join(map(str, numbered[:10]))}"
                         f"{', ...' if len(numbered) > 10 else ''}); keep them if already imported, "
                         "and use readable ids for new rows"))
    total = faqs + docs
    if total > max_rows:
        warnings.append((0, f"{total} rows; the importer limit is {max_rows}"))
    return {"file": path, "rows": total, "faqs": faqs, "documents": docs, "with_last_day": dated,
            "_ids": dict(seen), "_heads": heads,
            "errors": [{"line": l, "message": m} for l, m in errors],
            "warnings": [{"line": l, "message": m} for l, m in sorted(warnings)]}


def across(results):
    """Problems that only show when the files are read together."""
    out, owner = [], {}
    for r in results:
        for rid, line in r["_ids"].items():
            if rid in owner:
                f, l = owner[rid]
                out.append({"message": f"id {rid!r} is in {f} (line {l}) and {r['file']} (line {line}); "
                                       "give each file its own id prefix, and never move a row between files "
                                       "(the importer treats a moved row as deleted and added)"})
            else:
                owner[rid] = (r["file"], line)
    for i, a in enumerate(results):
        for b in results[i + 1:]:
            for la, ha in a["_heads"]:
                for lb, hb in b["_heads"]:
                    if similarity(ha, hb) >= DUP_SIMILARITY:
                        out.append({"message": f"{a['file']} line {la} and {b['file']} line {lb} look like the same "
                                               f"fact ({ha!r} / {hb!r}); keep it in one file only"})
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("files", nargs="+", metavar="FILE")
    p.add_argument("--today", default=dt.date.today().isoformat())
    p.add_argument("--max-rows", type=int, default=500)
    p.add_argument("--alias", action="append", default=[], metavar="NAME=column",
                   help="treat column NAME as one of: " + ", ".join(sorted(KNOWN)))
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    today = parse_day(a.today)
    if not today:
        p.error("--today must be YYYY-MM-DD")
    extra = {}
    for al in a.alias:
        name, _, col = al.partition("=")
        if col not in KNOWN:
            p.error(f"--alias {al}: column must be one of {', '.join(sorted(KNOWN))}")
        extra[norm_key(name)] = col
    results = []
    for f in a.files:
        try:
            results.append(check(f, today, a.max_rows, extra))
        except (OSError, UnicodeDecodeError, csv.Error) as e:
            print(f"cannot read {f}: {e}", file=sys.stderr)
            return 2
    cross = across(results) if len(results) > 1 else []
    for r in results:
        r.pop("_ids"), r.pop("_heads")
    if a.json:
        out = results[0] if len(results) == 1 else {"files": results, "across_files": cross}
        print(json.dumps(out, ensure_ascii=False, indent=2))
    else:
        for res in results:
            print(f"{res['file']}: {res['rows']} rows ({res['faqs']} FAQs, {res['documents']} documents, "
                  f"{res['with_last_day']} with last_day)")
            for kind in ("errors", "warnings"):
                print(f"{len(res[kind])} {kind}")
                for x in res[kind]:
                    where = f"line {x['line']}" if x["line"] else "file"
                    print(f"  {where}: {x['message']}")
        if len(results) > 1:
            print(f"across files: {len(cross)} warnings")
            for x in cross:
                print(f"  {x['message']}")
    return 1 if any(r["errors"] for r in results) else 0


if __name__ == "__main__":
    sys.exit(main())
